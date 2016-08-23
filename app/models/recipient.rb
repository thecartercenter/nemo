# Lightweight wrapper around a user or group, modeling useful properties
# in the context of broadcasts and other models.
class Recipient
  include ActiveModel::SerializerSupport

  attr_reader :object

  def initialize(object:)
    @object = object
  end

  def id
    "#{object.class.name.underscore}_#{object.id}"
  end

  def name
    prefix = I18n.t("recipient.prefixes.#{object.class.name.underscore}")
    "#{prefix}: #{object.name}"
  end
end
