# frozen_string_literal: true

class Game
  include ActiveModel::Serialization
  attr_accessor :world, :iteration, :all_snakes, :alive_snakes

  def setup(width: 100, height: 100)
    @iteration = 0
    @all_snakes = []
    @alive_snakes = []
    @width = width
    @height = height
    @world = Array.new(height) do |y| Array.new(width) do |x|
      type = (:wall if x.zero? || y.zero? || x == width - 1 || y == height - 1)

      type = :wall if rand(50) == 1
      Tile.new(x: x, y: y, type: type)
    end end

    $redis.set "map", Marshal.dump(world)

    @safe_tiles = @world.flatten.reject(&:wall?)
  end

  def spawn_new_snakes
    new_snakes = Snake.new_snakes

    @possible_spawn_points = @safe_tiles - @alive_snakes.map(&:occupied_space).flatten

    new_snakes.each do |snake|
      spawn_point = @possible_spawn_points.sample
      snake.set_position(spawn_point)
      @alive_snakes.push(snake)
      @possible_spawn_points = @possible_spawn_points.without(spawn_point)
    end
  end

  def tick
    @alive_snakes = Snake.alive.all
    @items = Item.all.to_a

    process_intents
    process_item_pickups

    kill_colliding_snakes

    spawn_new_snakes
    spawn_new_items

    @iteration += 1
  end

  def process_item_pickups
    @items.each do |item|
      collecting_snake = @alive_snakes.detect { |snake| snake.head == item.tile }
      next unless collecting_snake

      collecting_snake.items.push item.to_pickup
      collecting_snake.save
      item.destroy
    end
  end

  def spawn_new_items
    # Always have one item of food to pickup
    return unless !@items.any?(&:food?)

    item = Item.create!(
      item_type: "food",
      position: @possible_spawn_points.sample.to_h
    )
    @items.push(item)
  end

  def to_s
    chars = @world.map { |row| row.map(&:to_s) }
    @alive_snakes.each do |snake|
      chars[snake.head.y][snake.head.x] = snake.intent || "@"
      snake.segments.each do |segment|
        chars[segment.y][segment.x] = "~"
      end
    end

    chars.map(&:join).join("\n")
  end

  def as_json(_options = nil)
    {
      alive_snakes: @alive_snakes.map(&:to_game_hash),
      items: @items.map do |item|
        { itemType: item.item_type, position: item.position }
      end,
      leaderboard: Snake.leaderboard.map do |snake|
        { id: snake.id, name: snake.name, length: snake.length, isAlive: snake.alive? }
      end
    }
  end

  private

  # Snakes grow every 5 ticks or if they have food
  def should_snake_grow?(snake)
    snake.has_food? || (@iteration % 5).zero?
  end

  def process_intents
    @alive_snakes.each do |snake|
      current_position = snake.head
      new_y, new_x = case snake.intent || snake.last_intent
                     when "N" then [current_position.y - 1, current_position.x]
                     when "S" then [current_position.y + 1, current_position.x]
                     when "E" then [current_position.y, current_position.x + 1]
                     when "W" then [current_position.y, current_position.x - 1]
                     else [0, 0] # Dead on invalid move
                     end

      snake.move(@world[new_y][new_x], should_snake_grow?(snake))
    end
  end

  def kill_colliding_snakes
    # We need this to calculate collisions efficiently
    unsafe_tiles_this_tick = @alive_snakes.map(&:occupied_space).flatten

    dying_snakes = @alive_snakes.select do |snake|
      tile_for(snake.head).wall? ||
      # We expect the head to be in the list - if it's there a second time though,
      # that's a collision with either self of another snake
      unsafe_tiles_this_tick.count(snake.head) > 1
    end

    dying_snakes.each(&:kill)
    @alive_snakes -= dying_snakes
  end

  def tile_for(position)
    @world[position.y][position.x]
  end
end
