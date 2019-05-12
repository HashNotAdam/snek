# frozen_string_literal: true

require_relative 'map_drawer'

class HappiestPath
  def self.call(current_position:, game_state:, map:, previous_move:)
    new(
      current_position: current_position,
      game_state: game_state,
      map: map,
      previous_move: previous_move
    ).call
  end

  def initialize(current_position:, game_state:, map:, previous_move:)
    @current_position = current_position
    @game_state = game_state
    @map = map
    @previous_move = previous_move
  end

  DIRECTIONS = %w[N E S W].freeze
  OFFSETS = {
    'N' => { x: 0, y: -1 },
    'S' => { x: 0, y: 1 },
    'E' => { x: 1, y: 0 },
    'W' => { x: -1, y: 0 },
  }.freeze

  def call
    detect_best_path(scored_paths)    
  end

  private

  def scored_paths
    DIRECTIONS.map do |direction|
      positions = next_positions(direction, 10)
      values = map_values(positions)
      score = movement_score(values)
      {
        direction: direction,
        score: score
      }
    end
  end

  def next_positions(direction, num_moves)
    num_moves.times.map do |index|
      position = {
        "x" => @current_position[:x] + (OFFSETS[direction][:x] * (index + 1)),
        "y" => @current_position[:y] + (OFFSETS[direction][:y] * (index + 1))
      }

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

  def map_values(positions)
    map = MapDrawer.new(@game_state, @map).map_with_pieces

    positions.map do |position|
      map[position['y']][position['x']]
    end
  end

  def movement_score(values)
    scores = MapDrawer::OBSTACLE_CHARACTERS.map do |char|
      values.index(char) || 9000
    end
    scores.min
  end

  def detect_best_path(paths)
    max = paths.sort_by { |value| value[:score] }.reverse.first
    selectable_directions = paths.select do |value|
      value[:score] == max[:score]
    end
    
    return selectable_directions.first[:direction] unless @previous_move

    move = selectable_directions.detect do |value|
      value[:direction] == @previous_move
    end

    return move[:direction] if move

    selectable_directions.first[:direction]
  end
end
