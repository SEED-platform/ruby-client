require 'bundler/setup'
require 'seed'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # check if there is a seed.json file that has the user credentials
  if File.exist? '../seed.json'
    puts "Found seed.json which contains the SEED user credentials, overriding environment variables"
    j = JSON.parse(File.read('../seed.json'), symbolize_names: true)
    ENV['BRICR_SEED_HOST'] = j[:host]
    ENV['BRICR_SEED_USERNAME'] = j[:username]
    ENV['BRICR_SEED_API_KEY'] = j[:api_key]
  end
end
