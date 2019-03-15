# frozen_string_literal: true

class SmsMessageDecorator < ApplicationDecorator
  delegate_all

  def self.collection_decorator_class
    PaginatingDecorator
  end

  def self.object_class
    Sms::Message
  end

  # SMSes don't have edit or show pages.
  def default_path
    nil
  end
end
