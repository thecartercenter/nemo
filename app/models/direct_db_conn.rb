class DirectDBConn

  def initialize(table)
    @table = table
  end

  def insert(objects)
    column_names = objects.first.attributes.keys.join(', ')
    object_values = objects.map{ |o| convert_values_to_insert_syntax(o) }
    string_params = generate_string_params_template_from_attributes(objects.first.attributes)

    string_params = add_parenthesis_to_params_string(string_params);

    object_values = sanitize_object_values(object_values, string_params)

    sql_query_array = ["INSERT INTO #{@table} (#{column_names}) VALUES #{object_values.join(', ')}"]

    # Rescue because this uniqueness validation is already inserted on the model
    execute_sql_query_array(sql_query_array) rescue ActiveRecord::RecordNotUnique
  end

  def insert_select(objects, object_to_insert, field_to_select, table_to_select, field_to_where)
    # Get the objects that are going to be inserted on the db
    objects_to_insert = objects.map{ |u| u.send(object_to_insert).first }

    column_names = objects_to_insert.first.attributes.keys.join(', ')
    object_values = objects_to_insert.map{ |o| convert_values_to_insert_syntax(o) }
    string_params = generate_string_params_template_from_attributes(objects_to_insert.first.attributes)

    object_values = sanitize_object_values(object_values, string_params)
    # Change the value of the field with the name we want to SELECT on our INSERT..SELECT query
    object_values = change_field_value_with_field_name(object_values, column_names, field_to_select)

    # Build the select queries for each object using the params
    selects_queries = objects.map.with_index do |o, i|
      "SELECT #{object_values[i]} FROM #{table_to_select} WHERE #{field_to_where}=#{o.send(field_to_where)}"
    end

    unified_select_queries = selects_queries.join(' UNION ')

    sql_query_array = ["INSERT INTO #{@table} (#{column_names}) #{unified_select_queries}"]

    # Rescue because this uniqueness validation is already inserted on the model
    execute_sql_query_array(sql_query_array) rescue ActiveRecord::RecordNotUnique
  end

  def check_uniqueness(objects, field, row_start, columns=[])
    # Columns is used if you want to test the field against more than the columns with same name.
    # If none passed, we just use the field as the column
    columns << field if columns.empty?
    results = []

    columns.each do |column|
      string_params = generate_string_params_template_with_quotes(objects.length)
      field_values = objects.map{ |u| u.send(field.to_sym) }

      #Avoid executing queries if fields aren't present
      unless field_values.all?(&:nil?)
        sql_query_array = ["SELECT #{field} FROM #{@table} WHERE #{column} IN (#{string_params})", field_values].flatten

        results = execute_sql_query_array(sql_query_array).entries
      end
    end

    results
  end

  private

  def generate_string_params_template_from_attributes(attributes)
    attributes.map{ |k,v| v.is_a?(String) ? "'%s'" : '%s' }.join(', ')
  end

  def add_parenthesis_to_params_string(params_string)
    "(#{params_string})"
  end

  def change_field_value_with_field_name(object_values, column_names, field_name)
    id_field_index = column_names.split(', ').index(field_name)

    object_values.map do |values|
      values_as_array = values.split(',')
      values_as_array[id_field_index] = 'id'
      values_as_array.join(',')
    end
  end

  def generate_string_params_template_with_quotes(length)
    Array.new(length){'%s'}.map{|p| "'#{p}'" }.join(',')
  end

  def sanitize_object_values(object_values, string_params)
    object_values.map{ |o| sanitize_sql_query_array([string_params, o.split(',')].flatten) }
  end

  def add_parenthesis_on_each_value(object_values)
    object_values.map{ |o| "(#{o})" }
  end

  def convert_values_to_insert_syntax(object)
    object.attributes.map do |k, v|
      if (k == "created_at" || k == "updated_at")
        "NOW()"
      else
        (v.nil? ? 'NULL' : v)
      end
    end.join(',')
  end

  def execute_sql_query_array(sql_query_array)
    sanitized_query = sanitize_sql_query_array(sql_query_array)
    ActiveRecord::Base.connection.execute(sanitized_query)
  end

  def sanitize_sql_query_array(sql_query_array)
    ActiveRecord::Base.send(:sanitize_sql_array, sql_query_array)
  end
end
