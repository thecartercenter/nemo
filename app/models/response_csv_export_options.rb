# frozen_string_literal: true

# Custom options for exporting responses to CSV.
class ResponseCSVExportOptions
  include ActiveModel::Model

  attr_accessor :long_text_behavior

  LONG_TEXT_BEHAVIOR_OPTIONS = %w[exclude truncate include].freeze

  def initialize(**attribs)
    super
    self.long_text_behavior = "include"
  end
end
