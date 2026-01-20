module Campaigns
  class DispatchBroadcaster
    include ActionView::RecordIdentifier

    def initialize(logger: Rails.logger)
      @logger = logger
    end

    def broadcast_recipient(campaign, recipient)
      safe_broadcast("recipient", campaign.id, recipient.id) do
        Turbo::StreamsChannel.broadcast_replace_to(
          campaign,
          target: dom_id(recipient),
          partial: "campaigns/recipient_row",
          locals: { recipient: recipient }
        )
      end
    end

    def broadcast_progress(campaign)
      safe_broadcast("progress", campaign.id, nil) do
        Turbo::StreamsChannel.broadcast_replace_to(
          campaign,
          target: dom_id(campaign, :progress),
          partial: "campaigns/progress",
          locals: { campaign: campaign }
        )
      end
    end

    private

    attr_reader :logger

    def safe_broadcast(action, campaign_id, recipient_id)
      yield
    rescue StandardError => e
      scope = recipient_id ? "campaign #{campaign_id}, recipient #{recipient_id}" : "campaign #{campaign_id}"
      logger.warn("[Campaigns::DispatchBroadcaster] #{action} broadcast failed for #{scope}: #{e.class} #{e.message}")
    end
  end
end
