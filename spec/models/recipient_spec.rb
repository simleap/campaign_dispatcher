require "rails_helper"

RSpec.describe Recipient, type: :model do
  describe "email validations" do
    subject(:recipient) { create(:recipient) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:email).scoped_to(:campaign_id).case_insensitive }
    it { is_expected.to allow_value("person@example.com").for(:email) }
    it { is_expected.not_to allow_value("invalid-email").for(:email) }

    it "requires an email or phone number" do
      recipient.email = nil
      recipient.phone_number = nil

      expect(recipient).not_to be_valid
      expect(recipient.errors[:base]).to include("Email or phone number must be present")
    end

    it "normalizes email casing" do
      recipient.email = "User@Example.COM "
      recipient.validate

      expect(recipient.email).to eq("user@example.com")
    end
  end

  describe "phone number validations" do
    subject(:recipient) { create(:recipient, :phone_only) }

    it { is_expected.to allow_value("+15551234567").for(:phone_number) }
    it { is_expected.not_to allow_value("123-abc").for(:phone_number) }

    it "requires phone numbers to be unique within a campaign" do
      campaign = create(:campaign)
      create(:recipient, :phone_only, campaign: campaign, phone_number: "+15551234567")

      duplicate = build(:recipient, :phone_only, campaign: campaign, phone_number: "+15551234567")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:phone_number]).to include("has already been taken")
    end

    it "normalizes phone number formatting" do
      recipient.phone_number = " (555) 123-4567 "
      recipient.validate

      expect(recipient.phone_number).to eq("5551234567")
    end
  end
end
