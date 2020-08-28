# frozen_string_literal: true

Rails.application.config.after_initialize do
  Response.subscribe(OData::CacheListener.instance)
  Form.subscribe(OData::CacheListener.instance)
  User.subscribe(OData::CacheListener.instance)
end
