# frozen_string_literal: true

require "action_cable_client"
require "pry"

require "active_support"
require "active_support/core_ext/hash/indifferent_access"

require_relative "./util/client.rb"
require_relative "./random_snake.rb"

SNEK_HOST = ENV.fetch("SNEK_HOST") { "localhost:8080" }

$client = Client.new("http://#{SNEK_HOST}")

@snake_id = nil
@auth_token = nil
@move = nil

EventMachine.run do
  uri = "ws://#{SNEK_HOST}/cable"
  # We must send an Origin: header else rails is sad
  client = ActionCableClient.new(uri, "ClientChannel", true, "Origin" => "foo")

  client.connected do
    puts "successfully connected. You can watch at http://#{SNEK_HOST}"
    @map = $client.map
  end

  client.disconnected do
    @snake_name, @snake_id, @auth_token, @map = nil
    puts "Doh - disconnected - no snek running at #{SNEK_HOST}"

    sleep 1
    puts "Attempting to reconnect"
    client.reconnect!
  end

  client.received do |payload|
    puts "Received game state"

    return unless @map

    game_state = payload.fetch("message").with_indifferent_access
    my_snake = game_state.fetch("alive_snakes").detect do |snake|
      snake.fetch("id") == @snake_id
    end

    if my_snake
      # Yay - my_snake lives on - Let's get a move
      move = RandomSnake.new(my_snake, game_state, @map, @move).intent
      @move = move
      puts "Snake is at: #{my_snake.fetch(:head)} - Moving #{@snake_name} #{move}"
      $client.set_intent(@snake_id, move, @auth_token)
    else
      # Oh no - there is no my_snake.  Let's make one
      @snake_name = "Civil Serpent v4"
      puts "Making a new snake: #{@snake_name}"
      response = $client.register_snake(@snake_name)
      @snake_id = response.fetch("snake_id")
      # Auth token is required to authenticate moves for our snake
      @auth_token = response.fetch("auth_token")
    end
  end
end
