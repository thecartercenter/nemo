# frozen_string_literal: true

# Custom options for exporting responses via OData.
class ResponseODataExportOptions
  include ActiveModel::Model

  attr_accessor :mission_url, :api_url

  def initialize(*args)
    super
    self.api_url = if Settings.odata_api.present? || Rails.env.test?
                     "#{mission_url}/odata/v1"
                   else
                     "Coming soon"
                   end
  end
end
