# elo_rating

`elo_rating` helps you calculate [Elo ratings](https://en.wikipedia.org/wiki/Elo_rating_system), a rating system used primary for Chess, but can be used anywhere you want to determine an absolute ordering of things by doing many comparisons of a small number of things.

It can handle multiple players in one game and allows for custom K-factor functions.

- [API Documentation](https://mxhold.github.io/elo_rating/)

## Getting started

```ruby
gem install elo_rating
```

or add it to your Gemfile and run `bundle`:

```ruby
gem 'elo_rating', '~> 1.0'
```

## Usage

Say you have two players playing against each other in a match, both with initial ratings of 2000.

The second player wins.

To determine both player's updated ratings:

```ruby
match = EloRating::Match.new
match.add_player(rating: 2000)
match.add_player(rating: 2000, winner: true)
match.updated_ratings # => [1988, 2012]
```

This tells us that the first player's rating should go down 12 points and the second player's should go up 12 points.

You can chain the same function calls to achieve the same result:

```ruby
EloRating::Match.new.add_player(rating: 2000).add_player(rating: 2000, winner: true).updated_ratings # => [1988, 2012]
```

## Elo rating functions

The functions used in the above calculations are available for use directly:

### Expected score

Say you have 2 players, rated 1900 and 2000.

```ruby
EloRating.expected_score(1900, 2000) # => 0.360
```

The player rated 1900 has a 36% chance of winning.

### Rating adjustment

You can use the expected score and the results of an actual match to determine how an Elo rating should change.

The `EloRating.rating_adjustment` function takes an expected score and an actual score and returns how much a rating should go up or down.

Let's say we have the expected rating from above of 0.36 and the first player rated 1900 won the match, making their actual score 1.

We can use this to determine how much their rating should change:

```ruby
EloRating.rating_adjustment(0.36, 1) # => 15.36
```

This means their rating should now be 1915.

## K-factor

The K-factor is used in calculating the rating adjustment and determines how much impact the most recent game has on a player's rating.

It defaults to 24:

```ruby
EloRating::k_factor # => 24
```

You can change this to any number. With a lower K-factor, ratings are less volatile and change slower. Compare:

```ruby
EloRating::k_factor = 10
match = EloRating::Match.new
match.add_player(rating: 2000, winner: true)
match.add_player(rating: 2000)
match.updated_ratings # => [2005, 1995]
```

to:

```ruby
EloRating::k_factor = 20
match = EloRating::Match.new
match.add_player(rating: 2000, winner: true)
match.add_player(rating: 2000)
match.updated_ratings # => [2010, 1990]
```

You can also pass a block to provide a custom function to calculate the K-factor based on the player's rating:

```ruby
EloRating::set_k_factor do |rating|
  rating ||= 2000
  if rating < 2100
    32
  elsif 2100 <= rating && rating <= 2400
    24
  else
    16
  end
end
```

Then you can provide a rating to `EloRating.rating_adjustment` that will be used in your custom K-factor function:

```ruby
EloRating.rating_adjustment(0.75, 0) # => -24.0
EloRating.rating_adjustment(0.75, 0, rating: 2200) # => -18.0
EloRating.rating_adjustment(0.75, 0, rating: 2500) # => -12.0
```

You can also just specify a K-factor directly for a single rating adjustment:

```ruby
EloRating.rating_adjustment(0.75, 0, k_factor: 24) # => -18.0
```

*Note*: custom K-factor functions must not raise any exceptions when the rating is nil:

```ruby
EloRating::set_k_factor do |rating|
  rating / 100
end
# => ArgumentError: Error encountered in K-factor block when passed nil rating: undefined method `/' for nil:NilClass
```

## Thanks

Thanks to:

* Divergent Informatics for their [multiplayer Elo
calculator](http://elo.divergentinformatics.com/) used to verify calculations used in the development of this gem
* [Ian Hecker](https://github.com/iain) for the original [Elo](https://github.com/iain/elo) gem.

## License

Copyright © 2014 Maxwell Holder.

It is free software, and may be redistributed under the terms specified in the
LICENSE file.
