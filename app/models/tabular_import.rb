# frozen_string_literal: true

# For importing tabular spreadsheet data (CSV files).
class TabularImport
  include ActiveModel::Model

  attr_accessor :file, :name, :mission_id, :mission, :run_errors, :sheet

  validates :file, presence: true

  def initialize(*args)
    super
    self.mission = Mission.find(mission_id) if mission_id.present?
    self.run_errors = []
  end

  def run
    return unless open_sheet
    ApplicationRecord.transaction do
      process_data
      raise ActiveRecord::Rollback unless succeeded?
    end
  rescue CSV::MalformedCSVError => e
    add_run_error(:bad_csv, msg: e.to_s)
  end

  def succeeded?
    run_errors.empty?
  end

  def failed?
    run_errors.any?
  end

  protected

  # Assumes file is an open File object.
  # Opens as a CSV and sets `sheet` to an array of arrays with the data in the CSV.
  def open_sheet
    self.sheet = CSV.open(file.path).read
    delete_bom_prefix(sheet[0][0])
    sheet
  end

  # The "bom|utf-8" encoding could handle this automatically,
  # but that only works for files, not strings which are used in some cases.
  def delete_bom_prefix(str)
    str.sub!(/\A#{UserFacingCSV::BOM}/, "")
  end

  def add_run_error(message, opts = {})
    if message.is_a?(Symbol)
      opts = opts.merge(default: :"tabular_import.errors.#{message}")
      message = I18n.t("activerecord.errors.models.#{model_name.i18n_key}.#{message}", **opts)
    end
    run_errors << message
    false
  end

  def add_run_errors(errors)
    errors.each { |e| add_run_error(*e) }
  end

  def copy_validation_errors_for_row(row_number, errors)
    errors.details.each do |attribute, _|
      errors.full_messages_for(attribute).each do |error|
        add_run_error(I18n.t("operation.row_error", row: row_number, error: error))
      end
    end
  end
end
