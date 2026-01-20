class Campaign < ApplicationRecord
  has_many :recipients, dependent: :destroy

  enum :status, {
    pending: "pending",
    processing: "processing",
    completed: "completed"
  }, default: "pending"

  accepts_nested_attributes_for :recipients, allow_destroy: true

  validates :title, presence: true
  validate :at_least_one_recipient

  private

  def at_least_one_recipient
    if recipients.reject(&:marked_for_destruction?).blank?
      errors.add(:recipients, "must include at least one recipient")
    end
  end
end
