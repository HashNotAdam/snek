# frozen_string_literal: true

class Action
  LEFT = [-1, 0]
  UP = [0, -1]
  RIGHT = [1, 0]
  DOWN = [0, 1]

  def =(other)
    x == other.x && y == other.y
  end
end
