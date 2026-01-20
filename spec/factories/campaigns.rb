FactoryBot.define do
  sequence(:campaign_title) { |n| "Campaign #{n}" }

  factory :campaign do
    title { generate(:campaign_title) }
    status { "pending" }

    transient do
      recipients_count { 1 }
    end

    after(:build) do |campaign, evaluator|
      next if campaign.recipients.any?

      evaluator.recipients_count.times do
        campaign.recipients << build(:recipient, campaign: campaign)
      end
    end
  end
end
