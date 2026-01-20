class Recipient < ApplicationRecord
  belongs_to :campaign

  enum :status, {
    queued: "queued",
    sent: "sent",
    failed: "failed"
  }, default: "queued"

  before_validation :normalize_contact_fields

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validates :email, uniqueness: { scope: :campaign_id }, allow_nil: true
  validates :phone_number, uniqueness: { scope: :campaign_id }, allow_nil: true

  validate :email_or_phone_number_present
  validate :phone_number_format

  private

  def normalize_contact_fields
    self.email = email.to_s.strip.downcase.presence
    self.phone_number = normalize_phone_number(phone_number)
  end

  def normalize_phone_number(value)
    raw = value.to_s.strip
    return nil if raw.blank?

    normalized = raw.gsub(/[().\-\s]/, "")
    normalized.presence
  end

  def email_or_phone_number_present
    return if email.present? || phone_number.present?

    errors.add(:base, "Email or phone number must be present")
  end

  def phone_number_format
    return if phone_number.blank?

    return if phone_number.match?(/\A\+?[1-9]\d{9,14}\z/)

    errors.add(:phone_number, "is invalid")
  end
end
