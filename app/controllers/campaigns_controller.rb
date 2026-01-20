class CampaignsController < ApplicationController
  def new
    @campaign = Campaign.new
    @campaign.recipients.build
  end

  def create
    @campaign = Campaign.new(campaign_params)

    if @campaign.save
      redirect_to campaign_path(@campaign), notice: "Campaign created."
    else
      @campaign.recipients.build if @campaign.recipients.empty?
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @campaign = Campaign.find(params[:id])
    @recipients = @campaign.recipients.order(:id)
    @status_counts = @campaign.recipients.group(:status).count
  end

  def dispatch
    campaign = Campaign.find(params[:id])

    updated =
      Campaign.where(id: campaign.id, status: "pending").update_all(
        status: "processing",
        started_at: Time.current,
        updated_at: Time.current
      )

    if updated == 1
      DispatchCampaignJob.perform_async(campaign.id)
      redirect_to campaign_path(campaign), notice: "Dispatch started."
    else
      redirect_to campaign_path(campaign), alert: "Campaign is already processing or completed."
    end
  end

  private

  def campaign_params
    params.require(:campaign).permit(
      :title,
      recipients_attributes: %i[id name contact _destroy]
    )
  end
end
