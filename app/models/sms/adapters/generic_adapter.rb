# frozen_string_literal: true

module Sms
  module Adapters
    # Generic adapter configurable to match many gateways.
    class GenericAdapter < Adapter
      VALID_KEYS = %w[params response responseType matchHeaders].freeze
      REQUIRED_KEYS = %w[params.from params.body response].freeze

      def self.recognize_receive_request?(request, config:)
        generic_sms_config = extract_config(config)
        return false if generic_sms_config["params"].blank?
        params_match = generic_sms_config["params"].values - request.params.keys == []
        headers_match =
          if generic_sms_config["matchHeaders"].is_a?(Hash)
            generic_sms_config["matchHeaders"].all? { |k, v| request.headers[k] == v }
          else
            true
          end
        params_match && headers_match
      end

      def self.can_deliver?
        false
      end

      def self.extract_config(config)
        config.generic_sms_config&.deep_stringify_keys || {"params" => {}, "response" => ""}
      end

      def initialize(*args)
        super
        self.generic_sms_config = self.class.extract_config(config)
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
          from: request.params[generic_sms_config["params"]["from"]],
          to: nil,
          body: request.params[generic_sms_config["params"]["body"]],
          sent_at: Time.zone.now,
          adapter_name: service_name
        )
      end

      def validate(request)
      end

      def response_body(reply)
        escaped =
          case response_type_mime_symbol
          when :xml then CGI.escapeHTML(reply.body)
          when :json then reply.body.to_json
          else reply.body
          end
        format(generic_sms_config["response"].to_s, reply: escaped)
      end

      def response_content_type
        generic_sms_config["responseType"] || super
      end

      private

      attr_accessor :generic_sms_config

      # Gets the symbol associated with the responseType config per the Mime::Type library.
      # nil if none found.
      def response_type_mime_symbol
        return nil if generic_sms_config["responseType"].blank?
        Mime::Type.lookup(generic_sms_config["responseType"])&.symbol
      end
    end
  end
end
