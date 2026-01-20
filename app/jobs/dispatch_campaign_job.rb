class DispatchCampaignJob
  include Sidekiq::Job

  LOCK_NAMESPACE = 42_000

  def perform(campaign_id)
    with_campaign_lock(campaign_id) do
      campaign = Campaign.find(campaign_id)
      return if campaign.completed?

      campaign.update!(status: "processing", started_at: Time.current) if campaign.pending?
      campaign.update!(started_at: Time.current) if campaign.processing? && campaign.started_at.nil?

      campaign.recipients.where(status: "queued").order(:id).each do |recipient|
        begin
          maybe_sleep
          simulate_delivery!(recipient)

          recipient.update!(status: "sent", sent_at: Time.current, error_message: nil)
        rescue StandardError => e
          recipient.update!(status: "failed", error_message: e.message.to_s.truncate(200))
        end
      end

      campaign.update!(status: "completed", completed_at: Time.current)
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

  def simulate_delivery!(recipient)
    raise StandardError, "Simulated delivery failure" if recipient.contact.include?("fail")
  end
end
