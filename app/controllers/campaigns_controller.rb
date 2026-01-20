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
    @campaign = Campaign.includes(:recipients).find(params[:id])
  end

  private

  def campaign_params
    params.require(:campaign).permit(
      :title,
      recipients_attributes: %i[id name contact _destroy]
    )
  end
end

