# frozen_string_literal: true

ODataController.class_eval do
  before_action :refresh_schema

  def refresh_schema
    OData::Server.refresh_schema
  end
end
