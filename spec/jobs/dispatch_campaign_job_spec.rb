require "rails_helper"

RSpec.describe DispatchCampaignJob do
  it "delegates to the dispatch runner" do
    campaign = create(:campaign)
    runner = instance_double(Campaigns::DispatchRunner, call: true)

    allow(Campaigns::DispatchRunner).to receive(:new).with(campaign_id: campaign.id).and_return(runner)

    described_class.new.perform(campaign.id)

    expect(runner).to have_received(:call)
  end

  it "updates campaign and recipient statuses" do
    campaign = create(:campaign, recipients_count: 2, status: "pending", started_at: nil, completed_at: nil)

    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)

    described_class.new.perform(campaign.id)

    campaign.reload
    expect(campaign).to be_completed
    expect(campaign.started_at).to be_present
    expect(campaign.completed_at).to be_present

    campaign.recipients.each do |recipient|
      expect(recipient.reload).to be_sent
      expect(recipient.sent_at).to be_present
      expect(recipient.error_message).to be_nil
    end
  end

  it "raises when the runner fails so Sidekiq can retry" do
    campaign = create(:campaign)
    runner = instance_double(Campaigns::DispatchRunner)

    allow(runner).to receive(:call).and_raise(StandardError, "boom")
    allow(Campaigns::DispatchRunner).to receive(:new).and_return(runner)

    expect { described_class.new.perform(campaign.id) }.to raise_error(StandardError, "boom")
  end
end
