require 'spec_helper'

ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../config/environment', __dir__)

abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'

require 'simplecov'
SimpleCov.start 'rails' do
  add_filter "app/channels/application_cable/channel.rb"
  add_filter "app/channels/application_cable/connection.rb"
  add_filter "app/jobs/application_job.rb"
end

# Load Support Files
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  config.include RequestHelperMethods, type: :request

  config.include ActiveJob::TestHelper

  config.include Rails.application.routes.url_helpers

  config.fixture_path = "#{::Rails.root}/spec/fixtures"


  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!
end
