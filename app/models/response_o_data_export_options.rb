# frozen_string_literal: true

# Custom options for exporting responses via OData.
class ResponseODataExportOptions
  include ActiveModel::Model

  attr_accessor :request_url, :api_url

  def initialize(*args)
    super
    self.api_url = request_url.sub("/responses", "/odata/v1")
  end
end
