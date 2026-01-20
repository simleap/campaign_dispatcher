FactoryBot.define do
  sequence(:recipient_name) { |n| "Recipient #{n}" }
  sequence(:recipient_email) { |n| "recipient#{n}@example.com" }
  sequence(:recipient_phone_number) { |n| "+1555000#{n.to_s.rjust(4, "0")}" }

  factory :recipient do
    campaign
    name { generate(:recipient_name) }
    email { generate(:recipient_email) }
    phone_number { nil }
    status { "queued" }

    trait :phone_only do
      email { nil }
      phone_number { generate(:recipient_phone_number) }
    end

    trait :with_phone do
      phone_number { generate(:recipient_phone_number) }
    end

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
