FactoryBot.define do
  sequence(:recipient_name) { |n| "Recipient #{n}" }
  sequence(:recipient_contact) { |n| "recipient#{n}@example.com" }

  factory :recipient do
    campaign
    name { generate(:recipient_name) }
    contact { generate(:recipient_contact) }
    status { "queued" }

    trait :sent do
      status { "sent" }
      sent_at { Time.current }
      error_message { nil }
    end

    trait :failed do
      status { "failed" }
      error_message { "Simulated delivery failure" }
    end
  end
end

