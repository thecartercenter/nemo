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
            config["matchHeaders"].all? { |k, v| request.headers[k] == v }
          else
            true
          end
        params_match && headers_match
      end

      def self.can_deliver?
        false
      end

      def self.config
        configatron.generic_sms_config&.to_h&.deep_stringify_keys || {"params" => {}, "response" => ""}
      end

      def reply_style
        :via_response
      end

      def deliver(_message)
        raise NotImplementedError
      end

      def receive(request)
        # By now we know that the request has the from and body params.
        Sms::Incoming.new(
          from: request.params[self.class.config["params"]["from"]],
          to: nil,
          body: request.params[self.class.config["params"]["body"]],
          sent_at: Time.zone.now,
          adapter_name: service_name
        )
      end

      def validate(request)
      end

      def response_body(reply)
        format(self.class.config["response"].to_s, reply: reply.body)
      end
    end
  end
end
