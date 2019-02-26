# frozen_string_literal: true

# For importing tabular data (CSV, XLSX, etc.)
class TabularImport
  include ActiveModel::Model

  attr_accessor :file, :name, :mission_id, :mission, :run_errors

  validates :file, presence: true

  def initialize(**attribs)
    super
    self.mission = Mission.find(mission_id) if mission_id.present?
    self.run_errors = []
  end

  def succeeded?
    run_errors.empty?
  end

  def failed?
    run_errors.any?
  end

  protected

  def add_run_error(message, opts = {})
    if message.is_a?(Symbol)
      message = I18n.t("activerecord.errors.models.#{model_name.i18n_key}.#{message}", opts)
    end
    run_errors << message
  end

  def copy_validation_errors_for_row(row_number, errors)
    errors.keys.each do |attribute|
      errors.full_messages_for(attribute).each do |error|
        add_run_error(I18n.t("operation.row_error", row: row_number, error: error))
      end
    end
  end
end
