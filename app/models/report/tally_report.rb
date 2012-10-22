# contains methods common to all tally reports
class Report::TallyReport < Report::Report
  protected
    # extracts the row header values from the db_result object
    def get_row_header
      hashes = @db_result.extract_unique_tuples("question").collect{|tuple| {:name => tuple[0]}}
      Report::Header.new(hashes)
    end
  
    # extracts the col header values from the db_result object
    def get_col_header
      hashes = @db_result.extract_unique_tuples("answer_name", "answer_value").collect{|tuple| {:name => tuple[0], :sort_value => tuple[1]}}
      Report::Header.new(hashes)
    end

    # processes a row from the db_result by adding the contained data to the result
    def extract_data_from_row(db_row, db_row_idx)
      # get row and column indices (for result table) by looking them up in the header list
      r, c = @header_set.find_indices(:row => db_row["question"], :col => db_row["answer_name"])

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
end
