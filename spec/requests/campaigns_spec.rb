require "rails_helper"

RSpec.describe "Campaigns", type: :request do
  describe "POST /campaigns" do
    it "creates a campaign with recipients attributes" do
      params = {
        campaign: {
          title: "Winter outreach",
          recipients_attributes: [
            { name: "Ada Lovelace", contact: "ada@example.com" },
            { name: "Grace Hopper", contact: "grace@example.com" }
          ]
        }
      }

      expect do
        post campaigns_path, params: params
      end.to change(Campaign, :count).by(1).and change(Recipient, :count).by(2)

      campaign = Campaign.order(:id).last
      expect(response).to redirect_to(campaign_path(campaign))

      expect(campaign.title).to eq("Winter outreach")
      expect(campaign.recipients.order(:id).pluck(:name, :contact, :status)).to eq(
        [
          [ "Ada Lovelace", "ada@example.com", "queued" ],
          [ "Grace Hopper", "grace@example.com", "queued" ]
        ]
      )
    end

    it "returns 422 when missing title" do
      params = {
        campaign: {
          title: "",
          recipients_attributes: [
            { name: "Ada Lovelace", contact: "ada@example.com" }
          ]
        }
      }

      expect do
        post campaigns_path, params: params
      end.not_to change(Campaign, :count)

      expect(response).to have_http_status(422)
      expect(response.body).to include("Title can&#39;t be blank")
    end

    it "returns 422 when missing recipients" do
      params = {
        campaign: {
          title: "No recipients",
          recipients_attributes: []
        }
      }

      expect do
        post campaigns_path, params: params
      end.not_to change(Campaign, :count)

      expect(response).to have_http_status(422)
      expect(response.body).to include("Recipients must include at least one recipient")
    end
  end
end
