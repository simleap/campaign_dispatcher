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

  it "marks a recipient failed and continues when an error occurs" do
    campaign = create(:campaign, recipients_count: 2)
    job = described_class.new
    call_count = 0

    allow(job).to receive(:maybe_sleep) do
      call_count += 1
      raise StandardError, "Boom" if call_count == 1
    end

    job.perform(campaign.id)

    recipients = campaign.recipients.order(:id)
    first_recipient = recipients.first.reload
    second_recipient = recipients.second.reload

    expect(first_recipient).to be_failed
    expect(first_recipient.error_message).to include("Boom")
    expect(second_recipient).to be_sent
  end

  it "is idempotent when re-run (does not re-process sent/failed)" do
    campaign = create(:campaign, status: "processing", started_at: Time.current)
    queued = campaign.recipients.first
    queued.update!(email: "queued@example.com")
    sent = create(:recipient, :sent, campaign: campaign, email: "sent@example.com", sent_at: Time.current)
    failed = create(:recipient, :failed, campaign: campaign, email: "failed@example.com")

    sent_at_before = sent.sent_at
    error_before = failed.error_message

    travel 1.hour do
      described_class.new.perform(campaign.id)
    end

    expect(sent.reload.sent_at).to eq(sent_at_before)
    expect(failed.reload.error_message).to eq(error_before)
    expect(queued.reload).to be_sent
  end

  it "sets started_at if missing while processing" do
    campaign = create(:campaign, status: "processing", started_at: nil)

    described_class.new.perform(campaign.id)

    expect(campaign.reload.started_at).to be_present
  end
end
