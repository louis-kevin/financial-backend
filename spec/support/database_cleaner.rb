# frozen_string_literal: true

require 'database_cleaner/active_record'

RSpec.configure do |config|
  DatabaseCleaner.strategy = :deletion

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.before(:all) do
    DatabaseCleaner.start
  end

  config.after(:all) do
    DatabaseCleaner.clean
  end
end
