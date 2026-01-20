RSpec.configure do |config|
  config.before do
    Recipient.delete_all
    Campaign.delete_all
  end
end

