class DispatchCampaignJob
  include Sidekiq::Job

  def perform(campaign_id)
    Campaigns::DispatchRunner.new(campaign_id: campaign_id).call
  rescue StandardError => e
    Rails.logger.error("[DispatchCampaignJob] #{e.class}: #{e.message}")
  end
end
