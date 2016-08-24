class DirectDBConn

  def initialize(table)
    @table = table
  end

  def insert(objects)
    column_names = escape_column_names(objects)

    object_values = objects.map { |o| convert_values_to_insert_syntax(o) }

    string_params = generate_string_params_template_from_class(objects.first.class)

    string_params = add_parenthesis_to_params_string(string_params)

    object_values = sanitize_object_values(object_values, string_params)

    sql_query_array = ["INSERT INTO #{@table} (#{column_names}) VALUES #{object_values.join(', ')}"]

    # Rescue because this uniqueness validation is already inserted on the model
    execute_sql_query_array(sql_query_array) rescue ActiveRecord::RecordNotUnique
  end

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
      "SELECT #{object_values[i]} FROM #{table_to_select} WHERE #{field_to_where}=#{o.send(field_to_where)}"
    end

    unified_select_queries = selects_queries.join(" UNION ")

    sql_query_array = ["INSERT INTO #{@table} (#{column_names}) #{unified_select_queries}"]

    # Rescue because this uniqueness validation is already inserted on the model
    execute_sql_query_array(sql_query_array) rescue ActiveRecord::RecordNotUnique
  end

  def check_uniqueness(objects, fields)
    sql = "SELECT #{fields.join(', ')} FROM #{@table} WHERE "
    field_values = fields.map { |f| objects.map { |u| u.send(f) } }.flatten
    string_params = generate_string_params_template_with_quotes(field_values.length)

    conditions = []

    fields.each do |field|
      #Avoid building query if fields aren't present
      unless field_values.all?(&:nil?)
        field_in_values_sql = ["#{field} IN (#{string_params})", field_values].flatten
        sanitized_query = sanitize_sql_query_array(field_in_values_sql)
        conditions << sanitized_query
      end
    end

    sql += conditions.join(" OR ")

    execute_sanitized_query(sql).entries.flatten if sql_have_where_in_clause(sql)
  end

  private

  # We need to iterate over every attribute in order to see whether *any* instance of that attribute is a String
  # Otherwise if the first object is null or does not otherwise parse as a string in a string column
  # it won't be escaped which will cause the insert to silently fail and makes devs trying to debug very sad
  # Deprecated for now
  def generate_string_params_template_from_objects(objects)
    # Create an array of all the values for each attribute
    attribute_values = []
    objects.each do |obj|
      obj.attributes.each_with_index do |(key, value), index|
        attribute_values[index] ||= []
        attribute_values[index] << value
      end
    end

    # Construct the params template
    params_template = []
    attribute_values.each do |v_array|
      if v_array.any? { |v| v.is_a?(String) }
        params_template << "'%s'"
      else
        params_template << "%s"
      end
    end
    params_template.join(", ")
  end

  def generate_string_params_template_from_class(klass)
    klass.columns_hash.map do |column, column_type|
      [:string, :text].include?(column_type.type) ? "'%s'" : "%s"
    end.join(", ")
  end

  def add_parenthesis_to_params_string(params_string)
    "(#{params_string})"
  end

  def change_field_value_with_field_name(object_values, column_names, field_name)
    id_field_index = column_names.split(", ").index("`#{field_name}`")

    object_values.map do |values_array|
      values_array[id_field_index] = "id"
      values_array
    end
  end

  def generate_string_params_template_with_quotes(length)
    Array.new(length) { "%s" }.map { |p| "'#{p}'" }.join(",")
  end

  def sanitize_object_values(object_values, string_params)
    # The 'gsub' is necessary to remove quoted nulls which can cause uniqueness failures
    object_values.map { |o| sanitize_sql_query_array([string_params, o].flatten).gsub("'NULL'", "NULL") }
  end

  def add_parenthesis_on_each_value(object_values)
    object_values.map { |o| "(#{o})" }
  end

  def convert_values_to_insert_syntax(object)
    object.attributes.map do |k, v|
      if (k == "created_at" || k == "updated_at")
        "NOW()"
      else
        (v.nil? ? "NULL" : v)
      end
    end
  end

  def sql_have_where_in_clause(sql)
    sql.include? " IN ("
  end

  def execute_sql_query_array(sql_query_array)
    sanitized_query = sanitize_sql_query_array(sql_query_array)
    execute_sanitized_query(sanitized_query)
  end

  def escape_column_names(objects)
    objects.first.attributes.keys.map { |k| "`#{k}`" }.join(", ")
  end

  def execute_sanitized_query(sanitized_query)
    ActiveRecord::Base.connection.execute(sanitized_query)
  end

  def sanitize_sql_query_array(sql_query_array)
    ActiveRecord::Base.send(:sanitize_sql_array, sql_query_array)
  end
end
