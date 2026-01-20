module Campaigns
  class MessageTemplates
    def initialize(campaign:, recipient:)
      @campaign = campaign
      @recipient = recipient
    end

    def email_subject
      "Updates from #{campaign.title}"
    end

    def email_body
      render_template("campaigns/dispatch_email")
    end

    def sms_body
      render_template("campaigns/dispatch_sms")
    end

    private

    attr_reader :campaign, :recipient

    def render_template(template)
      ApplicationController.render(
        template: template,
        formats: [ :text ],
        locals: { campaign: campaign, recipient: recipient }
      ).strip
    end
  end
end
