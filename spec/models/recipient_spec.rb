require "rails_helper"

RSpec.describe Recipient, type: :model do
  describe "email validations" do
    subject(:recipient) { build(:recipient) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:email).scoped_to(:campaign_id) }
    it { is_expected.to allow_value("person@example.com").for(:email) }
    it { is_expected.to disallow_value("invalid-email").for(:email) }

    it "requires an email or phone number" do
      recipient.email = nil
      recipient.phone_number = nil

      expect(recipient).not_to be_valid
      expect(recipient.errors[:base]).to include("Email or phone number must be present")
    end
  end

  describe "phone number validations" do
    subject(:recipient) { build(:recipient, :phone_only) }

    it { is_expected.to validate_uniqueness_of(:phone_number).scoped_to(:campaign_id) }
    it { is_expected.to allow_value("+15551234567").for(:phone_number) }
    it { is_expected.to disallow_value("123-abc").for(:phone_number) }
  end
end
