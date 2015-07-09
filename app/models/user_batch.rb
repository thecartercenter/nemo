class UserBatch
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  IMPORT_ERROR_CUTOFF = 50

  attr_accessor :file
  attr_reader :users

  validates :file, presence: true

  def initialize(attribs = {})
    @users = []
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
    data = Roo::Spreadsheet.open(file)

    # assume the first row is the header row
    headers = data.row(data.first_row)

    expected_headers = Hash[*%i{name phone phone2 email notes}.map do |field|
      [User.human_attribute_name(field), field]
    end.flatten]

    fields = Hash[*headers.map.with_index do |header,index|
      [index, expected_headers[header]]
    end.flatten]

    # validate headers
    if fields.values.any?(&:nil?)
      @validation_error = true
      errors.add(:file, :invalid_headers)
      return succeeded?
    end

    # create the users in a transaction in case of validation error
    User.transaction do

      # iterate over each row, creating users as we go
      data.each_row_streaming(offset: data.first_row).with_index do |row,row_index|
        # excel row numbers are 1-indexed
        row_number = 1 + data.first_row + row_index

        # stop processing rows after a certain number of errors
        # (we do this at the beginning of the loop to avoid adding a redundant
        # :too_many_errors error on the last loop iteration)
        if errors.count >= IMPORT_ERROR_CUTOFF
          # we pass the previous row number to the error message formatting
          # since the error count cutoff was surpassed by the previous rows,
          # not this row
          errors.add(:users, :too_many_errors, row: row_number - 1)
          break
        end

        # skip blank rows
        next if row.all?(&:blank?)

        # turn the row into an attribute hash
        attributes = Hash[*row.map do |cell|
          field = fields[cell.coordinate.column - 1]
          [field, cell.value.presence]
        end.flatten]

        # attempt to create the user with the parsed params
        user = User.create(attributes.merge(
          reset_password_method: "print",
          assignments: [Assignment.new(mission_id: mission.id, role: User::ROLES.first)]))

        # if the user has errors, add them to the batch's errors
        if !user.valid?
          user.errors.keys.each do |attribute|
            user.errors.full_messages_for(attribute).each do |error|
              row_error = I18n.t('user_batch.row_error', row: row_number, error: error)
              errors.add("users[#{row_index}].#{attribute}", row_error)
            end
          end
          @validation_error = true
        end

        users << user

      end # iteration over rows

      # now if there was a validation error with any user, rollback the transaction
      raise ActiveRecord::Rollback if @validation_error

    end # transaction

    # TODO: remove the uploaded file

    return succeeded?
  end
end
