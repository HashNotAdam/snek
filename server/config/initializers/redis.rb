# frozen_string_literal: true

$redis = Redis.new(
  url: ENV.fetch("REDIS_URL") do
    "redis://#{ENV['REDIS_HOST'] || 'localhost'}:6379/#{Rails.env.test? ? 1 : 0}"
  end
)
