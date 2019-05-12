# frozen_string_literal: true

class MapDrawer
  OBSTACLE_CHARACTERS = %w[O X $ * #]

  def initialize(game_state, map, my_snake)
    @game_state = game_state
    @map = map
    @my_snake = my_snake
  end

  def draw
    map_with_pieces.each { |a| puts a.join(" ") }
  end

  def map_with_pieces
    result = []

    @map.each do |map_row|
      result << map_row.dup
    end

    snakes.each do |snake|
      snake = snake.with_indifferent_access
      snake_is_mine = @my_snake["id"] == snake["id"]
      head = snake.fetch("head")

      result[head[:y]][head[:x]] = snake_is_mine ? "$" : "O"

      snake.fetch("body").each do |body_piece|
        result[body_piece[:y]][body_piece[:x]] =
          snake_is_mine ? "*" : "X"
      end
    end

    items.each do |item|
      position = item.fetch("position")
      result[position[:y]][position[:x]] = "V"
    end

    result
  end

  private

  def snakes
    @game_state.fetch("alive_snakes")
  end

  def items
    @game_state.fetch("items")
  end

  def moved(piece, x: 0, y: 0)
    {x: piece[:x] + x, y: piece[:y] + y}
  end
end
