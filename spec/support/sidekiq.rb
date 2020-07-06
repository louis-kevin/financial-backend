require 'sidekiq/testing'

RSpec.configure do |config|
  Sidekiq::Testing.fake!

  config.before(:each) do
    Sidekiq::Worker.clear_all
  end
end
