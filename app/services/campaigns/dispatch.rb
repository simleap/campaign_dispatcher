module Campaigns
  class Dispatch
    Result = Struct.new(:started, :message, keyword_init: true) do
      def started?
        started
      end
    end

    def initialize(campaign:, enqueuer: DispatchCampaignJob)
      @campaign = campaign
      @enqueuer = enqueuer
    end

    def call
      now = Time.current
      updated =
        Campaign.where(id: campaign.id, status: "pending").update_all(
          status: "processing",
          started_at: now,
          updated_at: now
        )

      if updated == 1
        enqueuer.perform_async(campaign.id)
        Result.new(started: true)
      else
        Result.new(started: false, message: "Campaign is already processing or completed.")
      end
    end

    private

    attr_reader :campaign, :enqueuer
  end
end
