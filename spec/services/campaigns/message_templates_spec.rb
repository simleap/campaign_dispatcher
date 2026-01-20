require "rails_helper"

RSpec.describe Campaigns::MessageTemplates do
  it "renders email and sms templates with campaign and recipient data" do
    campaign = build(:campaign, title: "Launch Plan")
    recipient = build(:recipient, name: "Taylor", campaign: campaign)

    templates = described_class.new(campaign: campaign, recipient: recipient)

    expect(templates.email_subject).to include("Launch Plan")
    expect(templates.email_body).to include("Taylor")
    expect(templates.email_body).to include("Launch Plan")
    expect(templates.sms_body).to include("Taylor")
    expect(templates.sms_body).to include("Launch Plan")
  end
end
