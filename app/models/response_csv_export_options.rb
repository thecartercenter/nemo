# frozen_string_literal: true

# Custom options for exporting responses to CSV.
class ResponseCSVExportOptions
  include ActiveModel::Model

  attr_accessor :long_text_behavior, :download_media, :download_xml, :download_csv

  LONG_TEXT_BEHAVIOR_OPTIONS = %w[exclude truncate include].freeze

  def initialize(*args)
    super
    self.long_text_behavior = "include"
  end
end
