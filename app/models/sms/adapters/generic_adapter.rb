# frozen_string_literal: true

module Sms
  module Adapters
    # Generic adapter configurable to match many gateways.
    class GenericAdapter < Adapter
      VALID_KEYS = %w[params response matchHeaders].freeze
      REQUIRED_KEYS = %w[params.from params.body response].freeze

      def self.recognize_receive_request?(request)
        return false if config["params"].blank?
        params_match = config["params"].values - request.params.keys == []
        headers_match =
          if config["matchHeaders"] && config["matchHeaders"].is_a?(Hash)
            request.headers.slice(*config["matchHeaders"].keys) == config["matchHeaders"]
          else
            true
          end
        params_match && headers_match
      end

      def self.can_deliver?
        false
      end

      def self.config
        configatron.generic_sms_config || {"params" => {}, "response" => ""}
      end

      def reply_style
        :via_response
      end

      def deliver(_message)
        raise NotImplementedError
      end

      def receive(request)
        params = request.params
        Sms::Incoming.new(
          from: params["from"],
          to: nil, # Frontline doesn't provide this.
          body: params["text"],
          sent_at: Time.zone.now, # Frontline doesn't supply this
          adapter_name: service_name
        )
      end

      def validate(request)
      end

      def response_body(reply)
        reply.body
      end
    end
  end
end
