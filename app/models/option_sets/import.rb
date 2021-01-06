# frozen_string_literal: true

module OptionSets
  # Imports an OptionSet from a spreadsheet.
  class Import < TabularImport
    attr_accessor :option_set, :level_count, :cur_nodes, :cur_ranks

    validates :name, presence: true

    protected

    def process_data
      headers, meta_headers, rows = cleaner.clean
      add_run_errors(cleaner.errors)
      return if failed?

      self.level_count = headers.size
      init_state_vars
      create_option_set_and_copy_any_errors(headers, meta_headers.value?(:coordinates))
      rows.each_with_index { |row, row_idx| process_row(row, row_idx) }
    end

    private

    def cleaner
      @cleaner ||= ImportDataCleaner.new(sheet)
    end

    def create_option_set_and_copy_any_errors(headers, geographic)
      self.option_set = OptionSet.create(
        mission: mission,
        name: name,
        levels: headers.map { |h| OptionLevel.new(name: h) },
        geographic: geographic,
        allow_coordinates: geographic,
        root_node: OptionNode.new
      )
      copy_validation_errors_for_row(1, option_set.errors) unless option_set.valid?
    end

    def process_row(row, row_idx)
      # Metadata about the option is included at the end of the row array.
      metadata = row.extract_options!

      row.each_with_index do |cell, col_idx|
        next if cur_nodes[col_idx].present? && cell == cur_nodes[col_idx].option.name

        if cell.present?
          option = create_option(row, cell, col_idx, metadata)
          create_option_node(row_idx, col_idx, metadata, option) if option.present?
        end

        reset_state_vars_after(col_idx)
      end
    end

    # Creates and returns an option, or nil if there were validation errors.
    # Adds any validation errors to the Import.
    def create_option(row, cell, col_idx, metadata)
      attribs = {mission: mission, name_locale_key => cell}

      # We use metadata as attributes of the leaf Option, except orig_row_num, id, and shortcode.
      # id and shortcode may result from importing an exported set, and are ignored.
      attribs.merge!(metadata.without(:orig_row_num, :id, :shortcode)) if last_cell_in_row?(row, col_idx)

      option = Option.create(attribs)
      if option.invalid?
        copy_validation_errors_for_row(metadata[:orig_row_num], option.errors)
        nil
      else
        option
      end
    end

    def create_option_node(row_idx, col_idx, metadata, option)
      parent = col_idx.zero? ? option_set.root_node : cur_nodes[col_idx - 1]

      node = parent.children.create(mission: mission, rank: cur_ranks[col_idx], option_set: option_set,
                                    option: option, sequence: row_idx + 1)

      if node.invalid?
        copy_validation_errors_for_row(metadata[:orig_row_num], node.errors)
      else
        cur_ranks[col_idx] += 1
        cur_nodes[col_idx] = node
      end
    end

    def name_locale_key
      :"name_#{configatron.preferred_locales[0]}"
    end

    def init_state_vars
      self.cur_nodes = Array.new(level_count)
      self.cur_ranks = Array.new(level_count, 0)
    end

    # Reset the all state var arrays to the right of current position.
    def reset_state_vars_after(col_idx)
      ((col_idx + 1)...level_count).each do |j|
        cur_nodes[j] = nil
        cur_ranks[j] = 0
      end
    end

    # Returns true if all cells after the given col_idx in the given row are blank.
    # Can be used to check if a given cell represents a leaf node in the option tree.
    def last_cell_in_row?(row, col_idx)
      row[col_idx + 1...level_count].all?(&:blank?)
    end

    def transaction
      if Rails.env.test? && ENV["NO_TRANSACTION_IN_IMPORT"]
        yield
      else
        OptionSet.transaction { yield }
      end
    end
  end
end
