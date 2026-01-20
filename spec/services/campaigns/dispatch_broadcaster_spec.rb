require "rails_helper"

RSpec.describe Campaigns::DispatchBroadcaster do
  it "broadcasts recipient and progress updates" do
    campaign = create(:campaign)
    recipient = campaign.recipients.first
    broadcaster = described_class.new

    expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).twice

    broadcaster.broadcast_recipient(campaign, recipient)
    broadcaster.broadcast_progress(campaign)
  end

  it "swallows errors when broadcasting fails" do
    campaign = create(:campaign)
    recipient = campaign.recipients.first
    broadcaster = described_class.new

    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to).and_raise(StandardError, "broadcast failed")

    expect { broadcaster.broadcast_recipient(campaign, recipient) }.not_to raise_error
    expect { broadcaster.broadcast_progress(campaign) }.not_to raise_error
  end
end
