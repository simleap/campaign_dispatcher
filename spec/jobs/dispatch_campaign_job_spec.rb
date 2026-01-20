require "rails_helper"

RSpec.describe DispatchCampaignJob do
  include ActiveSupport::Testing::TimeHelpers

  it "transitions a pending campaign to processing then completed" do
    campaign = create(:campaign, recipients_count: 2, status: "pending", started_at: nil, completed_at: nil)

    described_class.new.perform(campaign.id)

    campaign.reload
    expect(campaign).to be_completed
    expect(campaign.started_at).to be_present
    expect(campaign.completed_at).to be_present
  end

  it "updates queued recipients to sent with a timestamp" do
    campaign = create(:campaign, recipients_count: 2)
    recipients = campaign.recipients.order(:id).to_a

    described_class.new.perform(campaign.id)

    recipients.each do |recipient|
      recipient.reload
      expect(recipient).to be_sent
      expect(recipient.sent_at).to be_present
      expect(recipient.error_message).to be_nil
    end
  end

  it "marks one recipient failed and continues processing others" do
    campaign = create(:campaign, recipients_count: 2)
    ok, failing = campaign.recipients.order(:id).to_a
    ok.update!(contact: "ok@example.com")
    failing.update!(contact: "fail@example.com")

    described_class.new.perform(campaign.id)

    expect(ok.reload).to be_sent
    expect(failing.reload).to be_failed
    expect(failing.error_message).to eq("Simulated delivery failure")
    expect(campaign.reload).to be_completed
  end

  it "is idempotent when re-run (does not re-process sent/failed)" do
    campaign = create(:campaign, status: "processing", started_at: Time.current)
    queued = campaign.recipients.first
    queued.update!(contact: "queued@example.com")
    sent = create(:recipient, :sent, campaign: campaign, contact: "sent@example.com", sent_at: Time.current)
    failed = create(:recipient, :failed, campaign: campaign, contact: "failed@example.com")

    sent_at_before = sent.sent_at
    error_before = failed.error_message

    travel 1.hour do
      described_class.new.perform(campaign.id)
    end

    expect(sent.reload.sent_at).to eq(sent_at_before)
    expect(failed.reload.error_message).to eq(error_before)
    expect(queued.reload).to be_sent
  end
end
