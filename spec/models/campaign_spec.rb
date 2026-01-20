require "rails_helper"

RSpec.describe Campaign, type: :model do
  subject(:campaign) { build(:campaign) }

  it { is_expected.to validate_presence_of(:title) }

  it "requires at least one recipient" do
    campaign.recipients.clear

    expect(campaign).not_to be_valid
    expect(campaign.errors[:recipients]).to include("must include at least one recipient")
  end
end
