module Campaigns
  class DispatchRunner
    LOCK_NAMESPACE = 42_000

    def initialize(campaign_id:, delivery_service: DeliveryStub.new, broadcaster: DispatchBroadcaster.new, logger: Rails.logger)
      @campaign_id = campaign_id.to_i
      @delivery_service = delivery_service
      @broadcaster = broadcaster
      @logger = logger
    end

    def call
      with_campaign_lock do
        campaign = Campaign.find(campaign_id)
        return if campaign.completed?

        ensure_processing(campaign)
        broadcaster.broadcast_progress(campaign)

        campaign.recipients.where(status: "queued").order(:id).each do |recipient|
          process_recipient(campaign, recipient)
        end

        campaign.update!(status: "completed", completed_at: Time.current)
        broadcaster.broadcast_progress(campaign)
      end
    end

    private

    attr_reader :campaign_id, :delivery_service, :broadcaster, :logger

    def with_campaign_lock
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

    def ensure_processing(campaign)
      now = Time.current

      if campaign.pending?
        campaign.update!(status: "processing", started_at: now)
      elsif campaign.processing? && campaign.started_at.nil?
        campaign.update!(started_at: now)
      end
    end

    def process_recipient(campaign, recipient)
      begin
        delivery_service.deliver(campaign: campaign, recipient: recipient)
        update_recipient(recipient, status: "sent", sent_at: Time.current, error_message: nil)
      rescue StandardError => e
        update_recipient(recipient, status: "failed", error_message: e.message.to_s.truncate(200))
      ensure
        broadcaster.broadcast_recipient(campaign, recipient)
        broadcaster.broadcast_progress(campaign)
      end
    end

    def update_recipient(recipient, attrs)
      recipient.update!(attrs)
    rescue StandardError => e
      logger.error("[Campaigns::DispatchRunner] Failed to update recipient #{recipient.id}: #{e.class} #{e.message}")
    end
  end
end
