module Campaigns
  class DeliveryStub
    def initialize(template_builder: MessageTemplates, logger: Rails.logger)
      @template_builder = template_builder
      @logger = logger
    end

    def deliver(campaign:, recipient:)
      templates = template_builder.new(campaign: campaign, recipient: recipient)
      payload = {
        email_subject: templates.email_subject,
        email_body: templates.email_body,
        sms_body: templates.sms_body
      }

      simulate_delay
      logger.info("[Campaigns::DeliveryStub] Prepared message payload for recipient #{recipient.id}")
      payload
    end

    private

    attr_reader :template_builder, :logger

    def simulate_delay
      return if Rails.env.test?

      sleep(rand(1..3))
    end
  end
end
