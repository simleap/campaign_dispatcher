class Recipient < ApplicationRecord
  belongs_to :campaign

  enum :status, {
    queued: "queued",
    sent: "sent",
    failed: "failed"
  }, default: "queued"

  validates :name, presence: true
  validates :contact, presence: true, uniqueness: { scope: :campaign_id }
end
