# frozen_string_literal: true

Rails.application.config.after_initialize do
  # Note: Only concrete (not abstract) classes can use Wisper.
  Response.subscribe(OData::CacheListener.instance)
  Answer.subscribe(OData::CacheListener.instance)
  Form.subscribe(OData::CacheListener.instance)
  User.subscribe(OData::CacheListener.instance)
  Question.subscribe(OData::CacheListener.instance)
  Questioning.subscribe(OData::CacheListener.instance)
  QingGroup.subscribe(OData::CacheListener.instance)
rescue ActiveRecord::NoDatabaseError => e
  # No database is okay, but this should allow the app to avoid crashing so one can be created.
end
