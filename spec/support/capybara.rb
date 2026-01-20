Capybara.server = :puma, { Silent: true }

ENV["PATH"] =
  ENV.fetch("PATH", "")
    .split(File::PATH_SEPARATOR)
    .reject { |path| path == "/opt/homebrew/bin" }
    .join(File::PATH_SEPARATOR)

Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
  end
end
