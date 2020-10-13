# frozen_string_literal: true

module OData
  NAMESPACE = "NEMO"
  BASE_PATH = "/odata/v1"

  # User-friendly, doesn't need to be URL safe.
  def self.responses_name(form_id, form_name)
    if Settings.use_data_factory_slugs.present?
      responses_slug(form_id, form_name)
    else
      "Responses: #{form_name}"
    end
  end

  # URL safe, doesn't need to be user-friendly.
  def self.responses_url(form_id, form_name)
    if Settings.use_data_factory_slugs.present?
      responses_slug(form_id, form_name)
    else
      "Responses-#{form_id}"
    end
  end

  # Both user-friendly-ish and URL safe.
  def self.responses_slug(form_id, form_name)
    "Responses-#{form_name.gsub(/[^a-z1-9]/i, '-')}-#{form_id}"
  end
end
