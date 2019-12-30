# frozen_string_literal: true

# a test request to the sms decoder
class Sms::Test
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  extend ActiveModel::Translation

  attr_accessor :from, :body, :name
  attr_reader   :errors

  def initialize(attribs = {})
    @errors = ActiveModel::Errors.new(self)
    attribs.each { |k, v| instance_variable_set("@#{k}", v) }
  end

  def persisted?
    false
  end

  # The following method are needed to be minimally implemented for ActiveModel::Errors

  def read_attribute_for_validation(attr)
    send(attr)
  end
end
