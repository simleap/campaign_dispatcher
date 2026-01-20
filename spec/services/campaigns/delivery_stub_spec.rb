require "rails_helper"

RSpec.describe Campaigns::DeliveryStub do
  it "returns a payload with rendered templates" do
    campaign = build(:campaign, title: "Weekly Update")
    recipient = build(:recipient, name: "Avery", campaign: campaign)

    payload = described_class.new.deliver(campaign: campaign, recipient: recipient)

    expect(payload[:email_subject]).to include("Weekly Update")
    expect(payload[:email_body]).to include("Avery")
    expect(payload[:sms_body]).to include("Weekly Update")
  end
end
