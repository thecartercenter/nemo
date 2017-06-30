# Class for efficiently inserting objects into the database using combined INSERTs and SELECT ... INSERT.
class FastInserter
  ATTRIBS_TO_SKIP = %w(id deleted_at old_id mission_old_id user_old_id)

  def initialize(table)
    @table = table
  end

  # Inserts a large amount of objects in a single query.
  def insert(objects)
    column_names = escape_column_names(objects)
    object_values = objects.map { |o| convert_values_to_insert_syntax(o) }
    string_params = "(" << generate_string_params_template_from_class(objects.first.class) << ")"
    object_values = sanitize_object_values(object_values, string_params)
    sql_runner.run("INSERT INTO #{@table} (#{column_names}) VALUES #{object_values.join(', ')}")
  end

  # Inserts a large amount of objects based on a query of other objects using SELECT ... INSERT.
  def insert_select(objects, object_to_insert, field_to_select, table_to_select, field_to_where)
    # Get the objects that are going to be inserted on the db
    objects_to_insert = objects.map { |u| u.send(object_to_insert).first }

    column_names = escape_column_names(objects_to_insert)
    object_values = objects_to_insert.map { |o| convert_values_to_insert_syntax(o) }
    string_params = generate_string_params_template_from_class(objects_to_insert.first.class)

    # Change the value of the field with the name we want to SELECT on our INSERT..SELECT query
    object_values = change_field_value_with_field_name(object_values, column_names, field_to_select)
    object_values = sanitize_object_values(object_values, string_params)

    # Build the select queries for each object using the params
    selects_queries = objects.map.with_index do |o, i|
      "SELECT #{object_values[i].gsub("'id'::uuid", 'id')} FROM #{table_to_select}
        WHERE #{table_to_select}.deleted_at IS NULL AND #{field_to_where}=#{o.send(field_to_where)}"
    end

    unified_select_queries = selects_queries.join(" UNION ")

    sql_runner.run("INSERT INTO #{@table} (#{column_names}) #{unified_select_queries}")
  end

  # Checks uniqueness across multiple columns using SQL.
  def check_uniqueness(objects, fields)
    sql = "SELECT #{fields.join(', ')} FROM #{@table} WHERE #{@table}.deleted_at IS NULL AND "
    field_values = fields.map { |f| objects.map { |u| u.send(f) } }.flatten
    string_params = (["'%s'"] * field_values.length).join(",")

    conditions = []

    fields.each do |field|
      # Avoid building query if fields aren't present
      unless field_values.all?(&:nil?)
        field_in_values_sql = ["#{field} IN (#{string_params})", field_values].flatten
        sanitized_query = sql_runner.sanitize(*field_in_values_sql)
        conditions << sanitized_query
      end
    end

    sql += conditions.join(" OR ")

    sql_runner.run(sql).map(&:values).flatten.compact if sql_have_where_in_clause(sql)
  end

  private

  def generate_string_params_template_from_class(klass)
    klass.columns_hash.map do |column, column_type|
      if ATTRIBS_TO_SKIP.include?(column)
        nil
      else
        if [:string, :text].include?(column_type.type)
          "'%s'"
        elsif column_type.type == :uuid
          "'%s'::uuid"
        else
          "%s"
        end
      end
    end.compact.join(", ")
  end

  def change_field_value_with_field_name(object_values, column_names, field_name)
    id_field_index = column_names.split(", ").index("\"#{field_name}\"")

    object_values.map do |values_array|
      values_array[id_field_index] = "id"
      values_array
    end
  end

  def sanitize_object_values(object_values, string_params)
    # The 'gsub' is necessary to remove quoted nulls which can cause uniqueness failures
    object_values.map { |o| sql_runner.sanitize(*[string_params, o].flatten).gsub("'NULL'", "NULL") }
  end

  def add_parenthesis_on_each_value(object_values)
    object_values.map { |o| "(#{o})" }
  end

  def convert_values_to_insert_syntax(object)
    object.attributes.map do |k, v|
      if ATTRIBS_TO_SKIP.include?(k)
        nil
      elsif k == "created_at" || k == "updated_at"
        "NOW()"
      else
        v.nil? ? "NULL" : v
      end
    end.compact
  end

  def sql_have_where_in_clause(sql)
    sql.include? " IN ("
  end

  def escape_column_names(objects)
    (objects.first.attributes.keys - ATTRIBS_TO_SKIP).map { |k| "\"#{k}\"" }.join(", ")
  end

  def sql_runner
    SqlRunner.instance
  end
end
