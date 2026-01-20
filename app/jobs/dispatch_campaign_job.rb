class DispatchCampaignJob
  include Sidekiq::Job

  def perform(campaign_id)
    Campaigns::DispatchRunner.new(campaign_id: campaign_id).call
  end
end
