require 'roo'
require 'pp'

MAX_LEVEL_LENGTH = 20
MAX_OPTION_LENGTH = 45

namespace :option_set do
  desc "Import an option set from an XLS file."
  task :import => :environment do

    abort('No file given.') unless ENV['file'].present?
    abort('No mission given.') unless ENV['mission'].present?
    abort('No name given.') unless ENV['name'].present?

    mission = Mission.where(compact_name: ENV['mission']).first || abort('Mission not found.')

    headers, rows = load_and_clean_data(ENV['file'])

    ActiveRecord::Base.transaction do

      set = OptionSet.create(mission: mission, name: ENV['name'], geographic: ENV['geographic'].present?,
        levels: headers.map{ |h| OptionLevel.new(name: h) },
        root_node: OptionNode.new(mission: mission))

      # State variables.
      cur_options, cur_nodes, cur_ranks = [], [], []
      rows.each_with_index do |row, r|
        row.each_with_index do |cell, c|
          if cur_nodes[c].nil? || cell != cur_nodes[c].option.name
            if cell.present?
              # Create the node.
              parent = c == 0 ? set.root_node : cur_nodes[c-1]
              cur_ranks[c] = (cur_ranks[c] || 0) + 1
              cur_nodes[c] = parent.children.create!(mission: mission, rank: cur_ranks[c], option_set: set,
                option: Option.create!(mission: mission, name: cell))
            end

            # Reset the all state var arrays to the right of current position.
            (c+1...headers.size).each do |j|
              cur_nodes[j] = nil
              cur_ranks[j] = nil
            end
          end
        end
        print "Added row #{(r+1).to_s.ljust(6)}\r"
      end
    end
    print "\n"
  end

  def load_and_clean_data(path)
    puts 'Loading file.'
    sheet = Roo::Excelx.new(path).sheet(0)

    # Get headers from first row, strip nils, and chop long names.
    headers = sheet.row(1)
    headers = headers[0...headers.index(nil)] if headers.any?(&:nil?)
    headers.map!{ |h| h[0...MAX_LEVEL_LENGTH] }

    # Load and clean full set as array of arrays.
    puts 'Cleaning.'
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
    puts 'Sorting.'
    n = 0
    rows.sort_by!{ |r| n += 1; r + [n] }

    # Remove any duplicates (efficiently, now that we're sorted).
    puts 'Removing duplicates.'
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
