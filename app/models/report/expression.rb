# frozen_string_literal: true

# models an sql expression to be used in an SQL clause
# clause - the kind of clause that this expression is useful for
# sql_tplt - template for the sql fragment
# name - a name that can be used in an AS clause. should be unique per field type.
# chunks - parameters to be subbed into the sql template
class Report::Expression
  attr_reader :clause, :sql_tplt, :name, :sql, :chunks

  def initialize(params)
    params.each { |k, v| instance_variable_set("@#{k}", v) }

    # build sql fragment by substituting chunks for their placeholders
    @sql = sql_tplt
    chunks&.each { |k, v| @sql = @sql.gsub("__#{k.to_s.upcase}__", v.to_s) }
  end
end
