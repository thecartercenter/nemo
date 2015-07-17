class OptionSetImport
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include ActiveModel::AttributeAssignment

  MAX_LEVEL_LENGTH = 20
  MAX_OPTION_LENGTH = 45

  attr_accessor :mission_id, :name, :file
  attr_reader :option_set

  validates(:mission, presence: true)
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

  def create_option_set
    # check validity before processing spreadsheet
    return false if invalid?

    headers, rows = load_and_clean_data

    OptionSet.transaction do

      # create the option set
      @option_set = OptionSet.create!(
        mission: mission,
        name: name,
        levels: headers.map{ |h| OptionLevel.new(name: h) },
        root_node: OptionNode.new)

      # State variables.
      cur_nodes, cur_ranks = Array.new(headers.size), Array.new(headers.size, 0)
      rows.each_with_index do |row, r|
        row.each_with_index do |cell, c|
          if cur_nodes[c].nil? || cell != cur_nodes[c].option.name
            if cell.present?
              # Create the node.
              parent = c == 0 ? option_set.root_node : cur_nodes[c-1]
              cur_ranks[c] = cur_ranks[c] + 1
              cur_nodes[c] = parent.children.create!(
                mission: mission,
                rank: cur_ranks[c],
                option_set: option_set,
                option: Option.create!(mission: mission, name: cell))
            end

            # Reset the all state var arrays to the right of current position.
            (c+1...headers.size).each do |j|
              cur_nodes[j] = nil
              cur_ranks[j] = 0
            end
          end
        end
      end
    end

    return true
  end

  protected

    def load_and_clean_data
      sheet = Roo::Excelx.new(file).sheet(0)

      # Get headers from first row, strip nils, and chop long names.
      headers = sheet.row(1)
      headers = headers[0...headers.index(nil)] if headers.any?(&:nil?)
      headers.map!{ |h| h[0...MAX_LEVEL_LENGTH] }

      # Load and clean full set as array of arrays.
      rows = []
      (2..sheet.last_row).each do |r|
        row = sheet.row(r)[0...headers.size]

        next if row.all?(&:blank?)
        row.map!{ |c| c.blank? ? nil : c.to_s.strip[0...MAX_OPTION_LENGTH] }

        # Can't be any blank interior cells.
        raise "Error on row #{r}: blank interior cell." if blank_interior_cell?(row)

        rows << row
      end

      # Quit if there are no rows.
      raise "No rows to import." if rows.empty?

      # Sort array ensuring stability.
      n = 0
      rows.sort_by!{ |r| n += 1; r + [n] }

      # Remove any duplicates (efficiently, now that we're sorted).
      last = -1
      rows.reject!{ |r| last != -1 && rows[last] == r ? true : (last += 1) && false }

      [headers, rows]
    end

    def blank_interior_cell?(row)
      return false unless row.any?(&:nil?)

      # The portion of the array after the first nil should be all nils.
      !row[row.index(nil)..-1].all?(&:nil?)
    end

end
