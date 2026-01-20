class Campaign < ApplicationRecord
  has_many :recipients, dependent: :destroy

  enum :status, {
    pending: "pending",
    processing: "processing",
    completed: "completed"
  }, default: "pending"

  validates :title, presence: true
end
