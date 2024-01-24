require_relative '../lib/elo_rating.rb'

describe EloRating::Match do
  describe '#updated_ratings' do
    context 'simple match with two players and one winner' do
      it 'returns the updated ratings of all the players' do
        match = EloRating::Match.new
        match.add_player(rating: 2000)
        match.add_player(rating: 2000, winner: true)
        expect(match.updated_ratings).to eql [1988, 2012]
      end
    end

    context 'match with 3 players and one winner' do
      it 'returns the updated ratings of all the players' do
        match = EloRating::Match.new
        match.add_player(rating: 1900, winner: true)
        match.add_player(rating: 2000)
        match.add_player(rating: 2000)
        expect(match.updated_ratings).to eql [1931, 1985, 1985]
      end
    end

    context 'match with 3 players and no winner' do
      it 'returns the updated ratings of all the players' do
        match = EloRating::Match.new
        match.add_player(rating: 1900)
        match.add_player(rating: 2000)
        match.add_player(rating: 2000)
        expect(match.updated_ratings).to eql [1900, 2000, 2000]
      end
    end

    context 'match with 4 players and one winner' do
      it 'returns the updated ratings of all the players' do
        match = EloRating::Match.new
        match.add_player(rating: 1900)
        match.add_player(rating: 2000)
        match.add_player(rating: 2000)
        match.add_player(rating: 2100, winner: true)
        expect(match.updated_ratings).to eql [1894, 1991, 1991, 2123]
      end
    end

    context 'match with 4 players and two winners' do
      it 'returns the updated ratings of all the players' do
        match = EloRating::Match.new
        match.add_player(rating: 2000, winner: true)
        match.add_player(rating: 2000, winner: true)
        match.add_player(rating: 2100, winner: false)
        match.add_player(rating: 1500, winner: false)
        expect(match.updated_ratings).to eql [2008, 2008, 2085, 1499]
      end
    end

    context 'match with 4 players and three winners' do
      it 'returns the updated ratings of all the players' do
        match = EloRating::Match.new
        match.add_player(rating: 1900)
        match.add_player(rating: 2000, winner: true)
        match.add_player(rating: 2000, winner: true)
        match.add_player(rating: 2100, winner: true)
        expect(match.updated_ratings).to eql [1892, 2003, 2003, 2102]
      end
    end


    context 'match with 3 players and two winners' do
      it 'returns the updated ratings of all the players' do
        match = EloRating::Match.new
        match.add_player(rating: 2000, winner: true)
        match.add_player(rating: 2000, winner: true)
        match.add_player(rating: 2100, winner: false)
        expect(match.updated_ratings).to eql [2008,2008,2085]
      end
    end


    context 'match with 3 players and one winners' do
      it 'returns the updated ratings of all the players' do
        match = EloRating::Match.new
        match.add_player(rating: 2000, winner: true)
        match.add_player(rating: 2000, winner: false)
        match.add_player(rating: 2100, winner: false)
        expect(match.updated_ratings).to eql [2027,1988,2085]
      end
    end

    context 'custom K-factor function' do
      it 'uses the custom K-factor function' do
        EloRating::set_k_factor do |rating|
          rating || 0
        end

        match = EloRating::Match.new
        match.add_player(rating: 2000)
        match.add_player(rating: 2000, winner: true)
        expect(match.updated_ratings).not_to eql [2000, 2000]

        EloRating::k_factor = 24
      end
    end

    context 'multiple winners specified' do
      it 'raises an error' do
        match = EloRating::Match.new
        match.add_player(rating: 1000, winner: true)
        match.add_player(rating: 1000, winner: true)
        expect { match.updated_ratings }.to raise_error ArgumentError
      end
    end

    context 'place specified for one player but not all' do
      it 'raises an error' do
        match = EloRating::Match.new
        match.add_player(rating: 1000)
        match.add_player(rating: 1000, place: 2)
        expect { match.updated_ratings }.to raise_error ArgumentError
      end
    end
  end

  describe '#add_player' do
    context 'adding a player with a rating' do
      it 'creates a new player with the specified rating' do
        match = EloRating::Match.new
        expect(EloRating::Match::Player).to receive(:new).with({rating: 2000, match: match})

        match.add_player(rating: 2000)
      end

      it "appends the new player to the match's player" do
        match = EloRating::Match.new
        match.add_player(rating: 2000)

        expect(match.players.size).to eql 1
      end

      it 'returns the match itself so multiple calls can be chained' do
        match = EloRating::Match.new
        match.add_player(rating: 1000).add_player(rating: 2000)

        expect(match.players.size). to eql 2
      end
    end

    context 'adding a player with a non-numeric rating' do
      it 'raises an error' do
        match = EloRating::Match.new

        expect { match.add_player(rating: :foo) }.to raise_error(ArgumentError)
      end
    end

    context 'adding a player with a non-numeric place' do
      it 'raises an error' do
        match = EloRating::Match.new

        expect { match.add_player(rating: 1000, place: :foo) }.to raise_error(ArgumentError)
      end
    end

    context 'adding a player with both winner and place specified' do
      it 'raises an error' do
        match = EloRating::Match.new

        expect { match.add_player(rating: 1000, place: 2, winner: true) }.to raise_error ArgumentError
      end
    end
  end
end
