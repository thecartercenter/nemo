class UserBatch
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  IMPORT_ERROR_CUTOFF = 50
  BATCH_SIZE = 1000
  PERMITTED_ATTRIBS = %i[login name phone phone2 email birth_year gender
                         gender_custom nationality notes user_groups]
  EXPECTED_HEADERS =  %i[login name phone phone2 email birth_year gender nationality notes user_groups].freeze

  attr_accessor :file, :mission, :name
  attr_reader :users

  validates :file, presence: true

  def initialize(attribs = {})
    @users = []
    @inserter = FastInserter.new("users")
    attribs.each { |k,v| instance_variable_set("@#{k}", v) }
  end

  def persisted?
    false
  end

  def succeeded?
    !@error
  end

  def run
    @error = false
    @data = Roo::Spreadsheet.open(file).parse
    parse_headers(@data.shift)

    # create the users in a transaction in case of validation error
    User.transaction do
      parse_rows.each_with_index do |row, index|
        row[:assignments] = [Assignment.new(mission: mission, role: User::ROLES.first)]
        user = User.create(row)
        add_validation_error_messages(user, index + 2) if user.invalid?
        break if errors_reached_limit
      end
      raise ActiveRecord::Rollback if @error
    end
    !@error
  end

  private

  def parse_headers(row)
    # building map of translated field names to symbolic field names
    expected_headers = Hash[*EXPECTED_HEADERS.map do |field|
      [User.human_attribute_name(field), field]
    end.flatten]

    # Trim strings and remove blank headers from row
    row = row.map { |s| s.to_s.strip.presence }.compact

    # building map of column indices to field names
    @fields = Hash[*row.map.with_index do |header,index|
      [index, expected_headers[header]]
    end.flatten]

    # validate headers
    if @fields.values.any?(&:nil?)
      @error = true
      errors.add(:file, :invalid_headers)
      return false
    end
  end

  def number_of_iterations
    (@data.count / BATCH_SIZE.to_f).ceil
  end

  def parse_rows
    user_batch_attributes = []

    @data.each.with_index do |row, row_index|
      # skip blank rows
      next if row.all?(&:blank?)

      attributes = turn_row_into_attribute_hash(row)

      # Convert phone numbers to strings (they may come in as floats)
      %i(phone phone2).each do |k|
        if attributes[k].is_a?(Numeric)
          # Convert first to int, in case number is a float.
          # If we go straight to string, we may get ".0" at the end.
          attributes[k] = attributes[k].to_i.to_s
        end
      end

      attributes[:gender], attributes[:gender_custom] = coerce_gender(attributes[:gender])
      attributes[:nationality] = coerce_nationality(attributes[:nationality])
      attributes[:user_groups] = coerce_user_groups(attributes[:user_groups])

      user_batch_attributes << attributes
    end

    user_batch_attributes
  end

  def turn_row_into_attribute_hash(row)
    Hash[*row.map.with_index do |cell, i|
      @fields[i].nil? ? nil : [@fields[i], cell.presence]
    end.compact.flatten]
  end

  def create_users_instances(attribs, mission)
    attribs.map { |attrib| create_new_user(attrib, mission) }
  end

  def create_hash_table_with_fields_and_indexes(objects)
    @fields_hash_table = {
      "email" => {},
      "login" => {},
      "phone" => {}
    }

    # Group fields by array if they need to be checked together (in this case, phone and phone2)
    fields_to_check = [["email"], ["login"], ["phone", "phone2"]]

    fields_to_check.each { |field| populate_hash_with_field_and_occurrences(field, objects) }
  end

  def populate_hash_with_field_and_occurrences(field, objects)
    key = correct_field_key(field)

    objects.each do |object|
      field.each do |f|
        field_value = object.send(f)
        # Need to accept nil for email otherwise the db insert will complain of two emails as nil (not unique)
        (@fields_hash_table[key][field_value] ||= []) << object unless field_value.nil?
      end
    end
  end

  def validate_users_batch(users_batch)
    users_batch.each { |u| u.valid? }
  end

  def check_validation_errors(users, row_start)
    users.each_with_index do |user, index|
      row_number = row_start + index + 1
      add_validation_error_messages(user, row_number)

      if errors_reached_limit
        add_too_many_errors(row_number)
        break
      end
    end
  end

  def create_new_user(attributes, mission)
    User.new(attributes.slice(*PERMITTED_ATTRIBS).merge(
               reset_password_method: "print",
               admin: false,
               assignments: [Assignment.new(mission: mission, role: User::ROLES.first)],
               import_num: @import_num))
  end

  def add_validation_error_messages(user, row_number)
    # Remove persistence token error because it's not important on batch import
    user.errors.delete(:persistence_token)

    # if the user has errors, add them to the batch's errors
    unless user.errors.empty?
      user.errors.keys.each do |attribute|
        user.errors.full_messages_for(attribute).each do |error|
          add_error(error, attribute, row_number)
        end
      end
      @error = true
    end
  end

  # Takes a happy, uncoerced gender and stuffs it into a recognized box
  def coerce_gender(gender_string)
    return nil unless gender_string.present?
    gender_options = User::GENDER_OPTIONS.map { |g| [g, I18n.t("user.gender_options.#{g}")] }.to_h
    gender_selection = gender_options.find { |k, v| gender_string == v }
    gender = gender_selection.try(:first) || :specify
    gender_custom = gender_string if gender == :specify
    return gender.to_s, gender_custom
  end

  def coerce_nationality(nationality_string)
    return nil if nationality_string.blank?
    nationality_options = I18n.t("countries")
    nationality_selection = nationality_options.find { |k, v| nationality_string == v }
    nationality = nationality_selection.try(:first)
    nationality.to_s
  end

  def coerce_user_groups(user_group_names)
    (user_group_names || "").strip.split(";").map do |gn|
      user_group = UserGroup.find_by("LOWER(name) = :name AND mission_id = :mission_id",
        name: gn.strip.downcase,
        mission_id: mission.id
      )
      user_group = UserGroup.create!(name: gn.strip, mission_id: mission.id) unless user_group.present?
      user_group
    end
  end

  def error_is_on_persistence_token?(user)
    (user.errors.keys.length == 1) && (user.errors.keys.include? :persistence_token)
  end

  def add_error(error, attribute, row_number)
    row_error = I18n.t("operation.row_error", row: row_number, error: error)
    errors.add("users[#{row_number}].#{attribute}", row_error)
  end

  def add_too_many_errors(row_number)
    # we pass the previous row number to the error message formatting
    # since the error count cutoff was surpassed by the previous rows,
    # not this row
    errors.add(:users, :too_many_errors, row: row_number - 1) if errors_reached_limit
  end

  def errors_reached_limit
    errors.count >= IMPORT_ERROR_CUTOFF
  end

  def check_uniqueness_on_objects(_, fields)
    key = correct_field_key(fields)

    # Add errors on fields that aren't unique
    @fields_hash_table[key].each do |k,v|
      add_uniqueness_error(k, v, fields) if v.length !=1
    end
  end

  def add_uniqueness_error(key, value, fields)
    value.each do |object|
      fields.each { |f| add_uniqueness_error_checking_field_value(object, f, key) }
    end
  end

  def add_uniqueness_error_checking_field_value(object, field, value)
    object.errors.add(field, :taken) if object.send(field) == value
  end

  def check_uniqueness_on_db(objects, fields)
    results = @inserter.check_uniqueness(objects, fields) || []
    key = correct_field_key(fields)
    results.each do |result|
      (@fields_hash_table[key][result] || []).each do |object|
        fields.each { |f| add_uniqueness_error_checking_field_value(object, f, result) }
      end
    end
  end

  # If the field passed has more than one value, it means that the first value
  # is being used as the key on the hash table (they are being checked at the same time)
  def correct_field_key(field)
    field.first
  end

  def insert_assignments(users_batch)
    FastInserter.new("assignments").insert_select(
      users_batch, "assignments", "user_id", "users", "import_num")
  end
end
