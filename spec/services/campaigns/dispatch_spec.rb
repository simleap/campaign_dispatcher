require "rails_helper"

RSpec.describe Campaigns::Dispatch do
  it "marks a pending campaign as processing and enqueues the job" do
    campaign = create(:campaign, status: "pending", started_at: nil)
    enqueuer = class_double(DispatchCampaignJob, perform_async: true)

    result = described_class.new(campaign: campaign, enqueuer: enqueuer).call

    expect(result).to be_started
    expect(enqueuer).to have_received(:perform_async).with(campaign.id)

    campaign.reload
    expect(campaign).to be_processing
    expect(campaign.started_at).to be_present
  end

  it "returns a message and does not enqueue when already processing" do
    campaign = create(:campaign, status: "processing", started_at: Time.current)
    enqueuer = class_double(DispatchCampaignJob, perform_async: true)

    result = described_class.new(campaign: campaign, enqueuer: enqueuer).call

    expect(result).not_to be_started
    expect(result.message).to eq("Campaign is already processing or completed.")
    expect(enqueuer).not_to have_received(:perform_async)
  end
end
