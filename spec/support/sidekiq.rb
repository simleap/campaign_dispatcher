require "sidekiq/testing"

Sidekiq::Testing.fake!
Sidekiq.logger.level = Logger::WARN if defined?(Sidekiq.logger)

RSpec.configure do |config|
  config.before do
    Sidekiq::Worker.clear_all
  end
end
