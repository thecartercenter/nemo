# frozen_string_literal: true

# Custom options for exporting responses via OData.
class ResponseODataExportOptions
  include ActiveModel::Model

  attr_accessor :mission_url, :api_url

  def initialize(*args)
    super
    self.api_url = "#{mission_url}#{OData::BASE_PATH}"
  end
end
