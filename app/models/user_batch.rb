class UserBatch
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  IMPORT_ERROR_CUTOFF = 50
  BATCH_SIZE = 1000

  attr_accessor :file
  attr_reader :users

  validates :file, presence: true

  def initialize(attribs = {})
    @users = []
    @direct_db_conn = DirectDBConn.new('users')
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

  def persisted?
    false
  end

  def succeeded?
    !@validation_error
  end

  # creates users based on the data submitted via the users attribute
  def create_users(mission)
    # assume no errors to start with
    @validation_error = false

    # run UserBatch validations
    if invalid?
      @validation_error = true
      return succeeded?
    end

    # parse the input file as a spreadsheet
    @data = Roo::Spreadsheet.open(file)

    validate_headers

    unless @validation_error

      # create the users in a transaction in case of validation error
      User.transaction do

        row_start = @data.first_row
        @import_num = last_import_num_on_users

        user_batch_attributes = parse_rows(row_start)

        (0..number_of_iterations).each do |i|
          current_attributes_batch = user_batch_attributes[row_start-1, BATCH_SIZE]

          users_batch = create_users_instances(current_attributes_batch, mission)
          create_hash_table_with_fields_and_indexes(users_batch)

          validate_users_batch(users_batch)

          check_uniqueness_on_objects(users_batch, 'email')
          check_uniqueness_on_objects(users_batch, 'login')
          check_uniqueness_on_objects(users_batch, 'phone')
          check_uniqueness_on_objects(users_batch, 'phone2')

          check_uniqueness_on_db(users_batch, 'email', row_start)
          check_uniqueness_on_db(users_batch, 'login', row_start)
          check_uniqueness_on_db(users_batch, 'phone', row_start, ['phone','phone2'])
          check_uniqueness_on_db(users_batch, 'phone2', row_start, ['phone2','phone'])

          check_validation_errors(users_batch, row_start)

          break if errors_reached_limit

          @direct_db_conn.insert(users_batch)
          insert_assignments(users_batch)

          users.concat users_batch

          # Set row to start on the next batch
          row_start = ( (i + 1) * BATCH_SIZE ) + 1
        end

        # now if there was a validation error with any user, rollback the transaction
        raise ActiveRecord::Rollback if @validation_error

      end # transaction
    end

    return succeeded?
  end

  private

  def validate_headers
    # assume the first row is the header row
    headers = @data.row(@data.first_row)

    expected_headers = Hash[*%i{name phone phone2 email notes}.map do |field|
      [User.human_attribute_name(field), field]
    end.flatten]

    @fields = Hash[*headers.map.with_index do |header,index|
      [index, expected_headers[header]]
    end.flatten]

    # validate headers
    if @fields.values.any?(&:nil?)
      @validation_error = true
      errors.add(:file, :invalid_headers)
      return succeeded?
    end
  end

  def number_of_iterations
    users_rows_count = @data.count - 1
    ( users_rows_count / BATCH_SIZE.to_f ).ceil - 1
  end

  def parse_rows(offset)
    user_batch_attributes = []

    @data.each_row_streaming(offset: offset).with_index do |row, row_index|
      # excel row numbers are 1-indexed
      row_number = 1 + @data.first_row + row_index

      # skip blank rows
      next if row.all?(&:blank?)

      attributes = turn_row_into_attribute_hash(row)

      user_batch_attributes << attributes
    end

    user_batch_attributes
  end

  def turn_row_into_attribute_hash(row)
    Hash[*row.map do |cell|
      field = @fields[cell.coordinate.column - 1]
      [field, cell.value.presence]
    end.flatten]
  end

  def create_users_instances(attribs, mission)
    attribs.map{ |attrib| create_new_user(attrib, mission) }
  end

  def create_hash_table_with_fields_and_indexes(objects)
    @fields_hash_table = {
      'email' => {},
      'login' => {},
      'phone' => {}
    }

    columns = ['email', 'login', 'phone', 'phone2']

    columns.each{ |field| populate_hash_with_field_and_occurrences(field, objects) }
  end

  def populate_hash_with_field_and_occurrences(field, objects)
    key = correct_field_key(field)

    objects.map{ |o| o.send(field) }.each_with_index do |value, index|
      (@fields_hash_table[key][value] ||= []) << index unless value.nil?
    end
  end

  def validate_users_batch(users_batch)
    users_batch.each{ |u| u.valid? }
  end

  def check_validation_errors(users, row_start)
    users.each_with_index do |user, index|
      row_number = actual_row_number(row_start, index)
      add_validation_error_messages(user, row_number)

      if errors_reached_limit
        add_too_many_errors(row_number)
        break
      end
    end
  end

  def create_new_user(attributes, mission)
    User.new(attributes.merge(
               reset_password_method: "print",
               admin: false,
               assignments: [Assignment.new(mission: mission, role: User::ROLES.first)],
               batch_creation: true,
               import_num: @import_num += 1))
  end

  def add_validation_error_messages(user, row_number)
    # if the user has errors, add them to the batch's errors
    unless user.errors.empty?
      user.errors.keys.each do |attribute|
        if attribute != :persistence_token
          user.errors.full_messages_for(attribute).each do |error|
            add_error(error, attribute, row_number)
          end
        end
      end
      @validation_error = true unless error_is_on_persistence_token? user
    end
  end

  def error_is_on_persistence_token?(user)
    (user.errors.keys.length == 1) && (user.errors.keys.include? :persistence_token)
  end

  def add_error(error, attribute, row_number)
    row_error = I18n.t('import.row_error', row: row_number, error: error)
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

  def actual_row_number(row_start, index)
    index + row_start + 1
  end

  def check_uniqueness_on_objects(objects, field)
    key = correct_field_key(field)
    # Add errors on fields that aren't unique
    @fields_hash_table[key].each do |k,v|
      v.each{ |i| objects.at(i).errors.add(field, :taken) } if v.length != 1
    end
  end

  def check_uniqueness_on_db(objects, field, row_start, columns=[])
    results = @direct_db_conn.check_uniqueness(objects, field, row_start, columns)

    results.each do |result|
      @fields_hash_table[field][result.first].each do |index|
        object = objects.at(index)
        object.errors.add(field, :taken)
      end
    end
  end

  def correct_field_key(field)
    field.include?('phone') ? 'phone' : field
  end

  def insert_assignments(users_batch)
    DirectDBConn.new('assignments').insert_select(users_batch,
                                                  'assignments',
                                                  'user_id',
                                                  'users',
                                                  'import_num')
  end

  def last_import_num_on_users
    import_num = User.order("import_num DESC").first.try(:import_num)
    import_num.nil? ? 0 : import_num
  end
end
