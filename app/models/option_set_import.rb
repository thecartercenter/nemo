class OptionSetImport
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include ActiveModel::AttributeAssignment

  MAX_LEVEL_LENGTH = 20
  MAX_OPTION_LENGTH = 45

  attr_accessor :mission_id, :name, :file
  attr_reader :option_set

  validates(:name, presence: true)
  validates(:file, presence: true)

  def initialize(attributes={})
    assign_attributes(attributes)
  end

  def persisted?
    false
  end

  def mission
    @mission ||= Mission.find(mission_id) if mission_id.present?
  end

  def mission=(mission)
    self.mission_id = mission.try(:id)
    @mission = mission
  end

  def run(_options)
    create_option_set
  end

  def create_option_set
    # check validity before processing spreadsheet
    validate

    return false if errors.present?

    headers, special_columns, rows = load_and_clean_data

    # check validity after loading and cleaning data
    return false if errors.present?

    allow_coordinates = special_columns.include?(:coordinates)

    OptionSet.transaction do

      # create the option set
      @option_set = OptionSet.create(
        mission: mission,
        name: name,
        levels: headers.map{ |h| OptionLevel.new(name: h) },
        geographic: allow_coordinates,
        allow_coordinates: allow_coordinates,
        is_standard: mission.nil?,
        root_node: OptionNode.new)


      add_errors_for_row(1, @option_set.errors) unless @option_set.valid?

      # State variables. cur_ranks has a default value of 0 to simplify the code below.
      cur_nodes, cur_ranks = Array.new(headers.size), Array.new(headers.size, 0)
      rows.each_with_index do |row, r|
        leaf_attribs = row.extract_options!
        row_number = leaf_attribs.delete(:_row_number)

        # drop the :id and :shortcode attributes when re-importing exported spreadsheets
        leaf_attribs.delete(:id)
        leaf_attribs.delete(:shortcode)


        row.each_with_index do |cell, c|
          next if cur_nodes[c].present? && cell == cur_nodes[c].option.name

          if cell.present?
            # Create the option.
            attribs = { mission: mission, name_locale_key => cell }
            # TODO: nicer check for leaf nodes
            attribs.merge!(leaf_attribs) if row[c+1...headers.size].all?(&:blank?)
            option = Option.create(attribs)

            if option.invalid?
              add_errors_for_row(row_number, option.errors)
            else
              parent = c == 0 ? option_set.root_node : cur_nodes[c-1]

              # Create the node.
              node = parent.children.create(
                mission: mission,
                rank: cur_ranks[c],
                option_set: option_set,
                option: option,
                sequence: r + 1,
                is_standard: mission.nil?
              )

              if node.invalid?
                add_errors_for_row(row_number, node.errors)
              else
                cur_ranks[c] += 1
                cur_nodes[c] = node
              end
            end
          end

          # Reset the all state var arrays to the right of current position.
          (c+1...headers.size).each do |j|
            cur_nodes[j] = nil
            cur_ranks[j] = 0
          end
        end
      end


      raise ActiveRecord::Rollback if errors.present?
    end

    errors.blank?
  end

  protected

    # TODO: Share code with UserBatch
    def add_errors_for_row(row_number, errors)
      errors.keys.each do |attribute|
        errors.full_messages_for(attribute).each do |error|
          self.errors.add("option_sets[#{row_number}].#{attribute}",
            I18n.t("operation.row_error", row: row_number, error: error))
        end
      end
    end

    def load_and_clean_data
      sheet = nil
      begin
        sheet = Roo::Spreadsheet.open(file).sheet(0)
      rescue TypeError => e
        if e.to_s =~ /not an Excel 2007 file/
          errors.add(:base, :wrong_type)
          return
        else
          raise e
        end
      end

      # Get headers from first row and strip nils
      headers = sheet.row(1)
      headers = headers[0...headers.index(nil)] if headers.any?(&:nil?)

      # Get special columns i18n values
      id_header = 'Id'
      coordinates_header = I18n.t('activerecord.attributes.option.coordinates')
      shortcode_header = I18n.t('activerecord.attributes.option.shortcode')

      # Find any special columns
      special_columns = {}
      headers.each_with_index do |h,i|
        if [id_header, coordinates_header, shortcode_header].include?(h)
          special_columns[i] = h.downcase.to_sym
        end
      end

      # Enforce maximum length limitation on headers
      headers.map!{ |h| h[0...MAX_LEVEL_LENGTH] }

      # Load and clean full set as array of arrays.
      rows = []
      (2..sheet.last_row).each do |r|
        row = sheet.row(r)[0...headers.size]

        attribs = { _row_number: r }

        # go through the special column indexes and extract those cells into the attribs hash
        attribs.merge!(Hash[*special_columns.keys.reverse.map { |i| [special_columns[i], row.delete_at(i)] }.flatten])

        next if row.all?(&:blank?)
        row.map!{ |c| c.blank? ? nil : c.to_s.strip[0...MAX_OPTION_LENGTH] }

        # Can't be any blank interior cells.
        if blank_interior_cell?(row)
          # TODO: i18n
          errors.add(:option_set, "Error on row #{r}: blank interior cell.")
          next
        end

        # add the attribs hash back as the last element in the row
        row << attribs

        rows << row
      end

      # Error out if there are no rows.
      if rows.empty?
        # TODO: i18n
        errors.add(:option_set, 'No rows to import.')
        return
      end

      # TODO: figure out how to sort and dedupe while still passing along the original row numbers
      # Sort array ensuring stability. Use JSON representation to flatten attribs hash.
      #n = 0
      #rows.sort_by!{ |r| n += 1; (r + [n]).to_json }

      # TODO: should this add an error?
      # Remove any duplicates (efficiently, now that we're sorted).
      #last = -1
      #rows.reject!{ |r| last != -1 && rows[last] == r ? true : (last += 1) && false }

      special_columns.keys.reverse.each { |i| headers.delete_at(i) }

      [headers, special_columns.values, rows]
    end

    def blank_interior_cell?(row)
      return false unless row.any?(&:nil?)

      # The portion of the array after the first nil should be all nils.
      !row[row.index(nil)..-1].all?(&:nil?)
    end

    def name_locale_key
      :"name_#{configatron.preferred_locale}"
    end
end
