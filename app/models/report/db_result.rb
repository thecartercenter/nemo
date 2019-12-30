# frozen_string_literal: true

# models the result rows returned by the db from the query
class Report::DbResult
  attr_reader :rows

  def initialize(rows)
    @rows = rows

    # debug print rows
    # rows.each{|row| pp row.attributes}
  end

  def has_col?(col)
    !@rows.empty? && @rows.first.attributes.key?(col)
  end

  # extracts unique tuples defined by the col names given in cols
  def extract_unique_tuples(*cols)
    # use a hash to make it fast
    tuple_hash = {}
    unique_tuples = []
    rows.each do |row|
      # get the tuple for this row
      tuple = cols.collect { |c| row[c] }

      # check if we've already seen this one
      unless tuple_hash[tuple]
        unique_tuples << tuple
        tuple_hash[tuple] = true
      end
    end

    unique_tuples
  end
end
