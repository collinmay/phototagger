require "rack/test"
require "rspec"
require "database_cleaner"

ENV["RACK_ENV"] = "test"

require_relative "../main.rb"

module RSpecMixin
  include Rack::Test::Methods
  def app
    TaggerApp
  end
end

RSpec.configure do |c|
  c.include RSpecMixin

  def session
    last_request.env["rack.session"].to_hash
  end

  def forge_session(hash)
    return {"rack.session" => {:version => 5}.merge(hash)}
  end
  
  c.before(:suite) do
    DatabaseCleaner.strategy = :transaction
#    DatabaseCleaner.clean_with(:transaction)
  end

  c.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
