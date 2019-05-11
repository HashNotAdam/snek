# frozen_string_literal: true

require "securerandom"

class Snake < ApplicationRecord
  COLORS = %w[
    #e6194b #3cb44b #ffe119 #4363d8 #f58231 #911eb4 #46f0f0 #f032e6 #bcf60c
    #fabebe #008080 #e6beff #9a6324 #fffac8 #800000 #aaffc3 #808000 #ffd8b1
    #000075 #808080
  ].freeze
  VALID_MOVES = %w[N S E W].freeze

  validates :name, presence: true
  validates :intent, inclusion: VALID_MOVES, allow_blank: true

  before_create :setup_snake

  def self.new_snakes
    where(head_position: nil)
  end

  def self.dead
    where.not(died_at: nil)
  end

  def self.alive
    where(died_at: nil).where.not(head_position: nil)
  end

  def self.leaderboard
    where("length > 0").order("length DESC, id ASC").limit(20)
  end

  def alive?
    head_position.present? && died_at.nil?
  end

  def setup_snake
    # Used to secure moves with the player
    self.auth_token = SecureRandom.uuid
    self.last_intent = VALID_MOVES.sample
    self.color = COLORS.sample
  end

  def head
    Position.new(head_position)
  end

  def segments
    segment_positions.map do |sp|
      Position.new(sp)
    end
  end

  def set_intent(intent)
    update_attributes!(intent: intent)
  end

  def set_position(initial_tile)
    self.head_position = initial_tile.to_h
    self.length = 1
    save!
  end

  def move(new_tile, should_grow)
    segment_positions.unshift head_position
    segment_positions.pop unless should_grow
    self.head_position = new_tile.to_h
    self.last_intent = intent || last_intent
    self.intent = nil
    self.length = segment_positions.count + 1 # For head

    items.each do |item|
      item["turns_left"] = item["turns_left"].to_i - 1
    end

    items.reject! { |item| item["turns_left"] <= 0 }
    save!
  end

  def should_grow?(iteration_count); end

  def has_food?
    items.detect { |i| i["item_type"] == "food" }.present?
  end

  def kill
    update_attributes!(died_at: Time.current)
  end

  def occupied_space
    [head] + segments
  end

  def to_game_hash
    {
      id: id,
      name: name,
      head: head,
      color: color,
      length: length,
      body: segments
    }
  end
end
