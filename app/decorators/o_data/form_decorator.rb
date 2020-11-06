# frozen_string_literal: true

module OData
  # Decorates forms for the OData API.
  class FormDecorator < ApplicationDecorator
    delegate_all

    # User-friendly, doesn't need to be URL safe.
    def responses_name
      return responses_slug if ENV["NEMO_USE_DATA_FACTORY"].present?
      "Responses: #{name}"
    end

    # URL safe, doesn't need to be user-friendly.
    def responses_url
      return responses_slug if ENV["NEMO_USE_DATA_FACTORY"].present?
      "Responses-#{id}"
    end

    # Both user-friendly-ish and URL safe.
    def responses_slug
      "Responses-#{name.gsub(/[^a-z1-9]/i, '-')}-#{id}"
    end
  end
end
