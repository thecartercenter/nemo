class Report::ListReport < Report::Report
  include Report::Gridable

  def as_json(options = {})
    h = super(options)
    h[:calculations_attributes] = calculations
    h[:data] = @data
    h[:headers] = @header_set ? @header_set.headers : {}
    h[:can_total] = can_total?
    h
  end

  protected

  attr_accessor :questions

  def prep_query(rel)
    joins = []
    self.questions = []

    # We need to sort by responses.id because rows for each response need to be contiguous in the
    # result set. If two responses have the exact same created_at, this may not be the case unless
    # we secondarily sort by ID.
    rel = rel.select("responses.id AS response_id").order("responses.created_at, responses.id")

    # add each calculation
    calculations.each_with_index do |c, idx|
      # if calculation is question-based, we add the question to the list of questions we must filter on
      if c.question1
        questions << c.question1
      # otherwise we add the attrib to the select clause
      else
        rel = rel.select(c.select_expressions.collect{|e| "#{e.sql} AS e#{idx}_#{e.name}"})
      end
      joins += c.joins
      rel = rel.joins(Results::Join.list_to_sql(c.joins))
    end

    # apply the question filter and answer select items if necessary
    unless questions.empty?
      rel = rel.select("questions.id AS question_id")
      joins = Results::Join.expand(joins).collect(&:name)
      Report::AnswerField.expressions_for_clause(:select, joins, tbl_pfx: "").each do |e|
        rel = rel.select("#{e.sql} AS answer_#{e.name}")
      end

      # question filter
      qing_ids = questions.map(&:questionings).flatten.map(&:id).map { |id| "'#{id}'" }.join(",")
      rel = rel.where("questionings.id IN (#{qing_ids})") unless qing_ids.empty?

      # Add order by answer rank to accommodate multilevel answers.
      rel = rel.order("answers.rank")

      # For select multiples, also need to sort the choices within the answer.
      rel = rel.order("answer_select_multiple_sort") if questions.any?(&:select_multiple?)
    end

    rel = rel.limit(response_limit)

    # apply filter
    apply_filter(rel)
  end

  def header_title(which)
    nil
  end

  def get_row_header
    nil
  end

  def get_col_header
    hashes = []
    calculations.each_with_index do |c, idx|
      hashes << {name: c.header_title, key: c}
    end
    Report::Header.new(title: nil, cells: hashes)
  end

  # processes a row from the db_result by adding the contained data to the result
  def extract_data_from_row(db_row, db_row_idx)
    # if the response ID changes, we have to extract the attrib-based values for this response
    if db_row["response_id"] != @last_response_id
      # increment the current row index (or set to 0 if not exist)
      @cur_row = @cur_row.nil? ? 0 : @cur_row + 1

      # for each attrib-based calculation, enter a value
      calculations.each_with_index do |c, idx|
        if c.arg1.is_a?(Report::AttribField)
          # get the col index
          col = @header_set[:col].find_key_idx(c)

          # get the name and type values
          name = db_row["e#{idx}_#{c.name_expr.name}"]
          type = db_row["e#{idx}_#{c.data_type_expr.name}"]
          cell = Report::Formatter.format(name, type, :cell)

          # enter the value
          @data.set_cell(@cur_row, col, cell)
        end
      end
    end

    # if this row has a question id
    if qid = db_row["question_id"]
      # get the calculation pertaining to the current question id
      cur_calc = calculations.detect{|c| c.arg1.is_a?(Report::AnswerField) && c.arg1.question.id == qid}

      # if calculation was found
      if cur_calc
        # get the col index for the calculation
        col = @header_set[:col].find_key_idx(cur_calc)

        # get the name and type values and do formatting
        name = extract_name_from_row(db_row, cur_calc)
        type = db_row["answer_#{cur_calc.data_type_expr.name}"]
        cell = Report::Formatter.format(name, type, :cell)

        # enter the cell value
        @data.set_cell(@cur_row, col, cell, append: true)
      end
    end

    # save the previous response id
    @last_response_id = db_row["response_id"]
  end

  def extract_name_from_row(db_row, calc)
    result_name = db_row["answer_#{calc.name_expr(false).name}"]
    result_value = db_row["answer_#{calc.name_expr(true).name}"]
    @options[:prefer_values] && result_value.present? ? result_value : result_name
  end

  # totaling is not appropriate
  def can_total?
    false
  end

  def truncatable?
    true
  end

  def data_table_dimensions
    # We start out with an empty table and let the Data class auto-grow it.
    # This prevents index out of bounds errors.
    {rows: 0, cols: @header_set[:col].size}
  end

  def remove_blank_rows
    # remove any blank rows from the data; don't have to worry about row headers as there are none
    (@data.rows.size-1).downto(0) do |i|
      @data.rows.delete_at(i) if @data.empty_row?(i)
    end
  end

  private

  def response_limit
    # We do plus one and delete the one extra later so that we know if there are more than the limit.
    limit_plus_one = RESPONSES_QUANTITY_LIMIT + 1
    questions.present? ? (limit_plus_one * questions.count) : limit_plus_one
  end
end
