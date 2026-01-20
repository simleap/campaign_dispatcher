require "rails_helper"

RSpec.describe Campaigns::DispatchRunner do
  let(:broadcaster) { instance_double(Campaigns::DispatchBroadcaster, broadcast_recipient: nil, broadcast_progress: nil) }
  let(:delivery_service) { instance_double(Campaigns::DeliveryStub, deliver: true) }

  before do
    allow(delivery_service).to receive(:deliver)
  end

  it "transitions a pending campaign to processing then completed" do
    campaign = create(:campaign, recipients_count: 2, status: "pending", started_at: nil, completed_at: nil)

    described_class.new(
      campaign_id: campaign.id,
      delivery_service: delivery_service,
      broadcaster: broadcaster
    ).call

    campaign.reload
    expect(campaign).to be_completed
    expect(campaign.started_at).to be_present
    expect(campaign.completed_at).to be_present
  end

  it "updates queued recipients to sent with a timestamp" do
    campaign = create(:campaign, recipients_count: 2)

    described_class.new(
      campaign_id: campaign.id,
      delivery_service: delivery_service,
      broadcaster: broadcaster
    ).call

    campaign.recipients.each do |recipient|
      recipient.reload
      expect(recipient).to be_sent
      expect(recipient.sent_at).to be_present
      expect(recipient.error_message).to be_nil
    end
  end

  it "is idempotent when re-run (does not re-process sent/failed)" do
    campaign = create(:campaign, status: "processing", started_at: Time.current)
    queued = campaign.recipients.first
    queued.update!(email: "queued@example.com")
    sent = create(:recipient, :sent, campaign: campaign, email: "sent@example.com", sent_at: Time.current)
    failed = create(:recipient, :failed, campaign: campaign, email: "failed@example.com")

    sent_at_before = sent.sent_at
    error_before = failed.error_message

    expect(delivery_service).to receive(:deliver).once

    described_class.new(
      campaign_id: campaign.id,
      delivery_service: delivery_service,
      broadcaster: broadcaster
    ).call

    expect(sent.reload.sent_at).to eq(sent_at_before)
    expect(failed.reload.error_message).to eq(error_before)
    expect(queued.reload).to be_sent
  end

  it "marks a recipient failed and continues when delivery errors" do
    campaign = create(:campaign, recipients_count: 2)
    call_count = 0
    failing_delivery = instance_double(Campaigns::DeliveryStub)

    allow(failing_delivery).to receive(:deliver) do
      call_count += 1
      raise StandardError, "Boom" if call_count == 1
    end

    described_class.new(
      campaign_id: campaign.id,
      delivery_service: failing_delivery,
      broadcaster: broadcaster
    ).call

    recipients = campaign.recipients.order(:id)
    first_recipient = recipients.first.reload
    second_recipient = recipients.second.reload

    expect(first_recipient).to be_failed
    expect(first_recipient.error_message).to include("Boom")
    expect(second_recipient).to be_sent
  end

  it "sets started_at if missing while processing" do
    campaign = create(:campaign, status: "processing", started_at: nil)

    described_class.new(
      campaign_id: campaign.id,
      delivery_service: delivery_service,
      broadcaster: broadcaster
    ).call

    expect(campaign.reload.started_at).to be_present
  end

  it "raises when the campaign does not exist so the job can retry" do
    runner = described_class.new(
      campaign_id: 999_999,
      delivery_service: delivery_service,
      broadcaster: broadcaster
    )

    expect { runner.call }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
