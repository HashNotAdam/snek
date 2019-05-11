# frozen_string_literal: true

class Item < ApplicationRecord
  validates :item_type, inclusion: ["food"]

  def tile
    Position.new(position)
  end

  def duration
    5 if food?
  end

  def to_pickup
    { item_type: item_type, turns_left: duration }
  end

  def food?
    item_type == "food"
  end
end
