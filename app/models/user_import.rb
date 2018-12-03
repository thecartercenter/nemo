# frozen_string_literal: true

# Imports users from CSV or XLSX.
class UserImport < TabularImport
  IMPORT_ERROR_CUTOFF = 50
  PERMITTED_ATTRIBS = %i[login name phone phone2 email birth_year gender
                         gender_custom nationality notes user_groups].freeze
  EXPECTED_HEADERS =  %i[login name phone phone2 email birth_year gender nationality notes user_groups].freeze

  attr_accessor :file, :mission_id, :col_idx_to_attr_map
  attr_reader :users

  validates :file, presence: true

  def initialize(file: nil, mission_id: nil, name: nil)
    self.file = file
    self.mission_id = mission_id
  end

  def persisted?
    false
  end

  def succeeded?
    errors.blank?
  end

  def run
    data = Roo::Spreadsheet.open(file).parse
    return unless parse_headers(data.shift)

    User.transaction do
      parse_rows(data).each_with_index do |row, index|
        row[:assignments] = [Assignment.new(mission_id: mission_id, role: User::ROLES.first)]
        user = User.create(row)
        add_validation_error_messages(user, index + 2) if user.invalid?
        add_too_many_errors(index + 2) && break if errors.count >= IMPORT_ERROR_CUTOFF
      end
      raise ActiveRecord::Rollback unless succeeded?
    end
  end

  private

  def parse_headers(row)
    invalid_headers = []
    self.col_idx_to_attr_map = row.map.with_index do |header, col_idx|
      header = header.to_s.strip.presence # Col values may be numbers
      if header.nil?
        attr = nil
      else
        attr = header_to_attr(header)
        invalid_headers << header if attr.nil?
      end
      [col_idx, attr]
    end.compact.to_h
    invalid_headers.any? ? add_header_error(invalid_headers) && false : true
  end

  # Returns an attribute symbol matching the given header. Returns nil if not found.
  def header_to_attr(header)
    human_to_symbol_map[header.downcase]
  end

  def human_to_symbol_map
    @human_to_symbol_map ||= EXPECTED_HEADERS.map { |h| [User.human_attribute_name(h).downcase, h] }.to_h
  end

  def parse_rows(rows)
    rows.map do |row|
      next(nil) if row.all?(&:blank?)
      attributes = row_to_attr_map(row)
      phones_to_string(attributes)
      attributes[:gender], attributes[:gender_custom] = coerce_gender(attributes[:gender])
      attributes[:nationality] = coerce_nationality(attributes[:nationality])
      attributes[:user_groups] = coerce_user_groups(attributes[:user_groups])
      attributes
    end.compact
  end

  # Converts phone numbers to strings (they may come in as floats)
  def phones_to_string(attributes)
    %i[phone phone2].each do |k|
      # Convert first to int, in case number is a float.
      # If we go straight to string, we may get ".0" at the end.
      attributes[k] = attributes[k].to_i.to_s if attributes[k].is_a?(Numeric)
    end
  end

  def row_to_attr_map(row)
    row.map.with_index do |cell, i|
      col_idx_to_attr_map[i].nil? ? nil : [col_idx_to_attr_map[i], cell.presence]
    end.compact.to_h
  end

  # Takes a happy, uncoerced gender and stuffs it into a recognized box
  def coerce_gender(gender_string)
    return nil if gender_string.blank?
    gender_options = User::GENDER_OPTIONS.map { |g| [g, I18n.t("user.gender_options.#{g}")] }.to_h
    gender = gender_options.find { |_, v| gender_string == v }&.first || :specify
    gender_custom = gender == :specify ? gender_string : nil
    [gender, gender_custom]
  end

  def coerce_nationality(nationality_string)
    return nil if nationality_string.blank?
    I18n.t("countries").find { |_, v| nationality_string == v }&.first
  end

  def coerce_user_groups(user_group_names)
    (user_group_names || "").strip.split(";").map do |gn|
      user_group = UserGroup.find_by("LOWER(name) = :name AND mission_id = :mission_id",
        name: gn.strip.downcase,
        mission_id: mission_id)
      user_group || UserGroup.create!(name: gn.strip, mission_id: mission_id)
    end
  end

  # Copies validation errors from user object to main import object.
  def add_validation_error_messages(user, row_number)
    return if user.errors.empty?
    user.errors.keys.each do |attribute|
      user.errors.full_messages_for(attribute).each do |error|
        errors.add(:base, I18n.t("operation.row_error", row: row_number, error: error))
      end
    end
  end

  def add_header_error(invalid_headers)
    errors.add(:base, :invalid_headers, headers: invalid_headers.map { |h| "'#{h}'" }.join(", "),
                                        count: invalid_headers.size)
  end

  def add_too_many_errors(row_number)
    errors.add(:base, :too_many_errors, row: row_number)
  end
end
