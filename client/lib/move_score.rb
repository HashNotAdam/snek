# frozen_string_literal: true

require_relative 'map_drawer'

class MoveScore
  def self.call(game_state:, map:, my_snake:, path_variables:)
    new(
      game_state: game_state,
      map: map,
      my_snake: my_snake,
      path_variables: path_variables
    ).call
  end

  def initialize(game_state:, map:, my_snake:, path_variables:)
    @current_position = path_variables[:current_position]
    @game_state = game_state
    @map = map
    @my_snake = my_snake
  end

  OFFSETS = {
    'N' => { x: 0, y: -1 },
    'S' => { x: 0, y: 1 },
    'E' => { x: 1, y: 0 },
    'W' => { x: -1, y: 0 },
  }.freeze
  PREDICTIONS = 3

  def call
    OFFSETS.keys.map do |direction|
      positions = next_positions(@current_position, direction, PREDICTIONS)
      values = map_values(positions)
      score = movement_score(values)
      {
        direction: direction,
        score: score
      }
    end
  end

  private

  def next_positions(new_position, direction, num_moves)
    num_moves.times.map do |index|
      position = offset_position(new_position, direction, index + 1)

      position['x'] = 0 if position['x'] < 0
      if position['x'] >= @map.first.length
        position['x'] = @map.first.length - 1
      end
      position['y'] = 0 if position['y'] < 0
      if position['y'] >= @map.first.length
        position['y'] = @map.length - 1
      end

      position
    end
  end

  def offset_position(position, direction, moves)
    {
      "x" => position[:x] + OFFSETS[direction][:x] * moves,
      "y" => position[:y] + OFFSETS[direction][:y] * moves
    }.with_indifferent_access
  end

  def map_values(positions)
    map = MapDrawer.new(@game_state, @map, @my_snake).map_with_pieces

    positions.map do |position|
      map[position['y']][position['x']]
    end
  end

  def movement_score(values)
    scores = MapDrawer::OBSTACLE_CHARACTERS.map do |char|
      values.index(char) || PREDICTIONS + 1
    end
    scores.min
  end

  def fruitful_paths(paths)
    max = paths.sort_by { |value| value[:score] }.reverse.first
    selectable_directions = paths.select do |value|
      value[:score] == max[:score]
    end
  end
end
