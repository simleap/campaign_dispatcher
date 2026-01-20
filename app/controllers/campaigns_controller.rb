class CampaignsController < ApplicationController
  before_action :set_campaign, only: %i[show edit update destroy dispatch_campaign]
  before_action :ensure_editable, only: %i[edit update]

  def index
    @campaigns = Campaign.includes(:recipients).order(created_at: :desc)
  end

  def new
    @campaign = Campaign.new
    ensure_recipient_fields(@campaign)
  end

  def create
    @campaign = Campaign.new(campaign_params)

    if @campaign.save
      redirect_to campaign_path(@campaign), notice: "Campaign created."
    else
      ensure_recipient_fields(@campaign)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @recipients = @campaign.recipients.order(:id)
  end

  def edit
    ensure_recipient_fields(@campaign)
  end

  def update
    if @campaign.update(campaign_params)
      redirect_to campaign_path(@campaign), notice: "Campaign updated."
    else
      ensure_recipient_fields(@campaign)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @campaign.destroy!
    redirect_to campaigns_path, notice: "Campaign deleted."
  end

  def dispatch_campaign
    result = Campaigns::Dispatch.new(campaign: @campaign).call

    if result.started?
      redirect_to campaign_path(@campaign), notice: "Dispatch started."
    else
      redirect_to campaign_path(@campaign), alert: result.message
    end
  end

  private

  def set_campaign
    @campaign = Campaign.find(params[:id])
  end

  def campaign_params
    params.require(:campaign).permit(
      :title,
      recipients_attributes: %i[id name email phone_number _destroy]
    )
  end

  def ensure_recipient_fields(campaign)
    return if campaign.recipients.reject(&:marked_for_destruction?).any?

    campaign.recipients.build
  end

  def ensure_editable
    return if @campaign.pending?

    redirect_to campaign_path(@campaign), alert: "Campaign has already been dispatched and can no longer be edited."
  end
end
