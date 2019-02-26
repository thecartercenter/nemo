# frozen_string_literal: true

module OptionSets
  # Imports an OptionSet from a spreadsheet or CSV file.
  class Import < TabularImport
    attr_accessor :option_set, :level_count, :cur_nodes, :cur_ranks

    validates :name, presence: true

    def run
      headers, special_columns, rows = cleaner.clean
      add_run_errors(cleaner.errors)
      return false if failed?

      self.level_count = headers.size
      init_state_vars

      transaction do
        create_option_set_and_copy_any_errors(headers, special_columns.value?(:coordinates))
        rows.each_with_index { |row, row_idx| process_row(row, row_idx) }
        raise ActiveRecord::Rollback if failed?
      end
    end

    private

    def cleaner
      @cleaner ||= ImportDataCleaner.new(file)
    end

    def create_option_set_and_copy_any_errors(headers, geographic)
      self.option_set = OptionSet.create(
        mission: mission,
        name: name,
        levels: headers.map { |h| OptionLevel.new(name: h) },
        geographic: geographic,
        allow_coordinates: geographic,
        is_standard: mission.nil?,
        root_node: OptionNode.new
      )
      copy_validation_errors_for_row(1, option_set.errors) unless option_set.valid?
    end

    def process_row(row, row_idx)
      # We don't need :id and :shortcode attributes. These may come in if re-importing exported spreadsheets.
      leaf_attribs = row.extract_options!.without(:id, :shortcode)
      orig_row_num = leaf_attribs.delete(:orig_row_num)

      row.each_with_index do |cell, col_idx|
        next if cur_nodes[col_idx].present? && cell == cur_nodes[col_idx].option.name

        if cell.present?
          option = create_option(row, cell, orig_row_num, col_idx, leaf_attribs)
          create_option_node(row_idx, orig_row_num, col_idx, option) if option.present?
        end

        reset_state_vars_after(col_idx)
      end
    end

    # Creates and returns an option, or nil if there were validation errors.
    # Adds any validation errors to the Import.
    def create_option(row, cell, orig_row_num, col_idx, leaf_attribs)
      attribs = {mission: mission, name_locale_key => cell}
      # TODO: nicer check for leaf nodes
      attribs.merge!(leaf_attribs) if row[col_idx + 1...level_count].all?(&:blank?)
      option = Option.create(attribs)
      if option.invalid?
        copy_validation_errors_for_row(orig_row_num, option.errors)
        nil
      else
        option
      end
    end

    def create_option_node(row_idx, orig_row_num, col_idx, option)
      parent = col_idx.zero? ? option_set.root_node : cur_nodes[col_idx - 1]

      node = parent.children.create(mission: mission, rank: cur_ranks[col_idx], option_set: option_set,
                                    option: option, sequence: row_idx + 1, is_standard: mission.nil?)

      if node.invalid?
        copy_validation_errors_for_row(orig_row_num, node.errors)
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

    def transaction
      if Rails.env.test? && ENV["NO_TRANSACTION_IN_IMPORT"]
        yield
      else
        OptionSet.transaction { yield }
      end
    end
  end
end
