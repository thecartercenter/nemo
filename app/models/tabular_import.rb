# frozen_string_literal: true

# For importing tabular data (CSV, XLSX, etc.)
class TabularImport
  include ActiveModel::Model

  attr_accessor :file, :name, :mission_id, :mission

  validates :file, presence: true

  def initialize(**attribs)
    super
    self.mission = Mission.find(mission_id) if mission_id.present?
  end
end
