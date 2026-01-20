require "rails_helper"

RSpec.describe DispatchCampaignJob do
  it "delegates to the dispatch runner" do
    campaign = create(:campaign)
    runner = instance_double(Campaigns::DispatchRunner, call: true)

    allow(Campaigns::DispatchRunner).to receive(:new).with(campaign_id: campaign.id).and_return(runner)

    described_class.new.perform(campaign.id)

    expect(runner).to have_received(:call)
  end

  it "does not raise if the runner fails" do
    campaign = create(:campaign)
    runner = instance_double(Campaigns::DispatchRunner)

    allow(runner).to receive(:call).and_raise(StandardError, "boom")
    allow(Campaigns::DispatchRunner).to receive(:new).and_return(runner)

    expect { described_class.new.perform(campaign.id) }.not_to raise_error
  end
end
