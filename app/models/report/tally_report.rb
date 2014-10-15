# Methods common to all tally reports.
class Report::TallyReport < Report::Report
  include Report::Gridable

  def as_json(options = {})
    h = super(options)
    h[:data] = @data
    h[:headers] = @header_set ? @header_set.headers : {}
    h[:can_total] = can_total?
    h
  end

  protected
    # extracts the row header values from the db_result object
    def get_row_header
      get_header(:row)
    end

    # extracts the col header values from the db_result object
    def get_col_header
      get_header(:col)
    end

    def get_header(type)
      prefix = type == :row ? "pri" : "sec"
      if has_grouping(type)
        hashes = @db_result.extract_unique_tuples("#{prefix}_name", "#{prefix}_value", "#{prefix}_type").collect do |tuple|
          {:name => Report::Formatter.format(tuple[0], tuple[2], :header), :key => tuple[0], :sort_value => tuple[1]}
        end
      else
        hashes = [{:name => I18n.t("report/report.tally"), :key => "tally", :sort_value => 0}]
      end
      Report::Header.new(:title => header_title(type), :cells => hashes)
    end

    # processes a row from the db_result by adding the contained data to the result
    def extract_data_from_row(db_row, db_row_idx)
      # get row and column indices (for result table) by looking them up in the header list
      row_key = has_grouping(:row) ? db_row["pri_name"] : "tally"
      col_key = has_grouping(:col) ? db_row["sec_name"] : "tally"
      r, c = @header_set.find_indices(:row => row_key, :col => col_key)

      # set the matching cell value
      @data.set_cell(r, c, get_result_value(db_row))
    end

    # extracts and casts the result value from the given result row
    def get_result_value(row)
      # counts will always be integers so we just cast to integer
      row["tally"].to_i
    end

    # totaling is appropriate
    def can_total?
      return true
    end

    # constructs a blank array of arrays matching the size of the headers
    def blank_data_table(db_result)
      @header_set[:row].collect{|h| Array.new(@header_set[:col].size)}
    end
end
