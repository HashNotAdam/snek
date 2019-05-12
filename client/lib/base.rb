# frozen_string_literal: true

class Base
  def prepare_training_environment(
    horizontal_pixels: Constants.ENV_WIDTH,
    vertical_pixels: Constants.ENV_HEIGHT
  )
    environment = Environment(width=horizontal_pixels,
                       height=vertical_pixels)
    environment.set_wall()
    environment.set_fruit()
    environment.set_snake()
    return environment
end
