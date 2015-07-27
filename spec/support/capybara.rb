require 'capybara/poltergeist'

Capybara.asset_host = 'http://localhost:3000'

Capybara.javascript_driver = :poltergeist

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, timeout: 15)
end