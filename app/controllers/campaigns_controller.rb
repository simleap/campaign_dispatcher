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

  private

  def campaign_params
    params.require(:campaign).permit(
      :title,
      recipients_attributes: %i[id name contact _destroy]
    )
  end
end
