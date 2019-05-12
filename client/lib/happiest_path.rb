# frozen_string_literal: true

require_relative 'map_drawer'
require_relative 'move_score'

class HappiestPath
  def self.call(current_position:, game_state:, map:, my_snake:, previous_move:)
    new(
      current_position: current_position,
      game_state: game_state,
      map: map,
      my_snake: my_snake,
      previous_move: previous_move,
    ).call
  end

  def initialize(
    current_position:, game_state:, map:, my_snake:, previous_move:
  )
    @current_position = current_position
    @game_state = game_state
    @map = map
    @my_snake = my_snake
    @previous_move = previous_move
  end

  def call
    start = Time.now

    paths = calculate_path_scores(@current_position, 1, ROUNDS_OF_PREDICTION)
    paths = longest_paths(paths)
    path = pick_a_path(paths)

    puts "Completed in #{Time.now - start} seconds"

    MapDrawer.new(@game_state, @map, @my_snake).draw

    path[:moves].first
  end

  private

  ROUNDS_OF_PREDICTION = 5

  def calculate_path_scores(
    position, current_depth, max_depth, aggregate_values = nil
  )
    aggregate_values ||= {
      moves: [], recent_positions: [], score: 0
    }
    path_moves = aggregate_values[:moves]
    new_paths = MoveScore.(
      game_state: @game_state,
      map: @map,
      my_snake: @my_snake,
      path_variables: {
        current_position: position,
        recent_positions: aggregate_values[:recent_positions]
      }
    )

    new_paths.each do |path|
      path[:moves] = path_moves.dup << path[:direction]
      path[:recent_positions] = aggregate_values[:recent_positions].last(4)
      path[:recent_positions] << "#{path[:position][:x]}:#{path[:position][:y]}"
      path[:aggregate_score] = aggregate_values[:score] + path[:score]
    end

    if current_depth < max_depth
      new_paths.each do |path|
        next if path[:score] < 1

        aggregate_values = {
          moves: path[:moves],
          recent_positions: path[:recent_positions],
          score: path[:aggregate_score]
        }

        path[:paths] = calculate_path_scores(
          offset_position(position, path[:direction]),
          current_depth + 1,
          max_depth,
          aggregate_values
        )
      end
    end

    new_paths
  end

  OFFSETS = {
    'N' => { x: 0, y: -1 },
    'S' => { x: 0, y: 1 },
    'E' => { x: 1, y: 0 },
    'W' => { x: -1, y: 0 },
  }.freeze

  def offset_position(position, direction)
    {
      "x" => position[:x] + OFFSETS[direction][:x],
      "y" => position[:y] + OFFSETS[direction][:y]
    }.with_indifferent_access
  end

  def longest_paths(paths, max_moves = 0, best_moves = [])
    paths.each do |values|
      aggregate_values = {
        moves: values[:moves],
        score: values[:aggregate_score],
      }

      if values[:moves].length > max_moves
        best_moves = [aggregate_values]
        max_moves = values[:moves].length
      elsif values[:moves].length == max_moves
        best_moves << aggregate_values
      end

      longest_paths(values[:paths], max_moves, best_moves) if values[:paths]
    end

    best_moves
  end

  def pick_a_path(paths)
    return { moves: ["N"], score: 0 } if paths.empty?

    max_score = paths.max_by { |path| path[:score] }
    paths.keep_if { |path| path[:score] == max_score[:score] }
    paths.first
  end
end
