# frozen_string_literal: true

require_relative 'lib/happiest_path'

class RandomSnake
  def initialize(my_snake, game_state, map, previous_move)
    # Game state is an hash with the following structure
    # {
    #   alive_snakes: [{snake}],
    #   leaderboard: []
    # }
    # Each snake is made up of the following:
    # {
    #   id: id,
    #   name: name,
    #   head: {x: <int>, y: <int>,
    #   color: <string>,
    #   length: <int>,
    #   body: [{x: <int>, y: <int>}, etc.]
    # }
    @game_state = game_state
    # Map is a 2D array of chars.  # represents a wall and '.' is a blank tile.
    # The map is fetched once - it does not include snake positions - that's in game state.
    # The map uses [y][x] for coords so @map[0][0] would represent the top left most tile
    @map = map

    @my_snake = my_snake
    @current_position = @my_snake.fetch("head")
    @previous_move = previous_move
  end

  def intent
    HappiestPath.(
      current_position: @current_position,
      game_state: @game_state,
      map: @map,
      my_snake: @my_snake,
      previous_move: @previous_move
    )
  end
end
