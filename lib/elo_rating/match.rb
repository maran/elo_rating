##
# This class represents a single game between a number of players.
class EloRating::Match

  # All the players of the match.
  attr_reader :players

  # Creates a new match with no players.
  def initialize
    @players = []
  end

  # Adds a player to the match
  #
  # ==== Attributes
  # * +rating+: the Elo rating of the player
  # * +winner+ (optional): boolean, whether this player is the winner of the match
  # * +place+ (optional): a number representing the rank of the player within the match; the lower the number, the higher they placed
  #
  # Raises an +ArgumentError+ if the rating or place is not numeric, or if
  # both winner and place is specified.
  def add_player(player_attributes)
    players << Player.new(player_attributes.merge(match: self))
    self
  end

  # Calculates the updated ratings for each of the players in the match.
  #
  # Raises an +ArgumentError+ if more than one player is marked as the winner or
  # if some but not all players have +place+ specified.
  def updated_ratings
    validate_players!
    players.map(&:updated_rating)
  end

  private

  def validate_players!
    raise ArgumentError, 'Not all players can be winners' if multiple_winners?
    raise ArgumentError, 'All players must have places if any do' if inconsistent_places?
  end

  def multiple_winners?
    players.select { |player| player.winner? }.size == players.size
  end

  def inconsistent_places?
    players.select { |player| player.place }.any? &&
      players.select { |player| !player.place }.any?
  end

  class Player
  # :nodoc:
    attr_reader :rating, :place, :match
    def initialize(*args)
      args = args.first

      @match = args[:match]
      @rating = args[:rating]
      @place = args[:place]
      @winner = args[:winner]

      validate_attributes!(rating: @rating, place: @place, winner: @winner)
    end

    def winner?
      @winner
    end

    def validate_attributes!(rating:, place:, winner:)
      raise ArgumentError, 'Rating must be numeric' unless rating.is_a? Numeric
      raise ArgumentError, 'Winner and place cannot both be specified' if place && winner
      raise ArgumentError, 'Place must be numeric' unless place.nil? || place.is_a?(Numeric)
    end

    def opponents
      match.players - [self]
    end

    def updated_rating
      (rating + total_rating_adjustments).round
    end

    def total_rating_adjustments
      # Place-based matches (used for draws and ranked finishes) are scored as a
      # round robin: every player is compared against every other. This is the
      # only path that gives a draw any movement — the winner path below treats a
      # winner-less table as a no-op.
      return place_based_adjustments if place_based?

      return 0 if self.all_winners.size == 0

      # If you win you get elo from all losing opponents
      if self.winner?
         losers.map do |opponent|
           rating_adjustment_against(opponent)
        end.reduce(0, :+)
      else
        # If you are a loser and there are multiple winners you lose against the average score
        # of all all winners combined
        if self.winners.length > 1
          ratings = self.winners.collect(&:rating)
          average_rating = ratings.sum(0.0) / ratings.size
          return EloRating.rating_adjustment(
            EloRating.expected_score(rating, average_rating),
            0,
            rating: rating
          )
        else
          # If there is only one winner just lose from that winner only
          return rating_adjustment_against(winners.first)
        end
      end
    end

    def rating_adjustment_against(opponent)
      adjustment = EloRating.rating_adjustment(
        expected_score_against(opponent),
        actual_score_against(opponent),
        rating: rating
      )

      # if you win but it's a shared win you share that win with all other winners
      if winner? && self.winners.size > 0
        return adjustment.to_f / self.all_winners.size
      end

      return adjustment
    end

    def expected_score_against(opponent)
      EloRating.expected_score(rating, opponent.rating)
    end

    def winners
      opponents.find_all{|x| x.winner?}
    end

    def losers
      opponents.find_all{|x| !x.winner?}
    end

    # this includes us
    def all_winners
      match.players.find_all{|x| x.winner?}
    end

    def actual_score_against(opponent)
      # There are no other winners and you are a winner
      if self.winner?
        return 1 
      end

      # If there are winners but you are not it, you lose
      return 0 if !winners.empty? && !self.winner?
    end

    # True when this is a place-based match (any player was given a place). The
    # match validates that places are all-or-nothing, so checking any player is
    # enough.
    def place_based?
      match.players.any? { |player| player.place }
    end

    # Score this player pairwise against every opponent using their finishing
    # places: 1 for placing ahead, 0 for behind, 0.5 for a tie.
    def place_based_adjustments
      opponents.map do |opponent|
        EloRating.rating_adjustment(
          expected_score_against(opponent),
          place_score_against(opponent),
          rating: rating
        )
      end.reduce(0, :+)
    end

    def place_score_against(opponent)
      if place == opponent.place
        0.5
      elsif placed_ahead_of?(opponent)
        1.0
      else
        0.0
      end
    end

    def placed_ahead_of?(opponent)
      if place && opponent.place
        place < opponent.place
      end
    end
  end
end

