class DispatchCampaignJob
  include Sidekiq::Job
  include ActionView::RecordIdentifier

  LOCK_NAMESPACE = 42_000

  def perform(campaign_id)
    with_campaign_lock(campaign_id) do
      campaign = Campaign.find(campaign_id)
      return if campaign.completed?

      campaign.update!(status: "processing", started_at: Time.current) if campaign.pending?
      campaign.update!(started_at: Time.current) if campaign.processing? && campaign.started_at.nil?
      broadcast_progress(campaign)

      campaign.recipients.where(status: "queued").order(:id).each do |recipient|
        begin
          maybe_sleep
          recipient.update!(status: "sent", sent_at: Time.current, error_message: nil)
        rescue StandardError => e
          recipient.update!(status: "failed", error_message: e.message.to_s.truncate(200))
        ensure
          broadcast_recipient(campaign, recipient)
          broadcast_progress(campaign)
        end
      end

      campaign.update!(status: "completed", completed_at: Time.current)
      broadcast_progress(campaign)
    end
  end

  private

  def with_campaign_lock(campaign_id)
    campaign_id = campaign_id.to_i
    locked = false

    ActiveRecord::Base.connection_pool.with_connection do |connection|
      lock_value = connection.select_value("SELECT pg_try_advisory_lock(#{LOCK_NAMESPACE}, #{campaign_id})")
      locked = ActiveModel::Type::Boolean.new.cast(lock_value)
      return unless locked

      yield
    ensure
      connection.execute("SELECT pg_advisory_unlock(#{LOCK_NAMESPACE}, #{campaign_id})") if locked
    end
  end

  def maybe_sleep
    return if Rails.env.test?

    sleep(rand(1..3))
  end

  def broadcast_recipient(campaign, recipient)
    Turbo::StreamsChannel.broadcast_replace_to(
      campaign,
      target: dom_id(recipient),
      partial: "campaigns/recipient_row",
      locals: { recipient: recipient }
    )
  end

  def broadcast_progress(campaign)
    Turbo::StreamsChannel.broadcast_replace_to(
      campaign,
      target: dom_id(campaign, :progress),
      partial: "campaigns/progress",
      locals: { campaign: campaign }
    )
  end
end
