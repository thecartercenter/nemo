module DirectDBConn
  class << self
    def insert(objects, table)
      string_params = generate_string_params_template(objects.length)
      column_names = objects.first.attributes.keys.join(', ')
      object_values = objects.map{|o| "(#{convert_values_to_insert_syntax(o)})"}
      # sql_query_array = ["INSERT INTO #{table} (#{column_names}) VALUES #{string_params}", object_values].flatten
      # TODO sanitize
      sql_query_array = ["INSERT INTO #{table} (#{column_names}) VALUES #{object_values.join(', ')}"]

      # Rescue because this uniqueness validation is already inserted on the model
      execute_sql_query_array(sql_query_array) rescue ActiveRecord::RecordNotUnique
    end

    def check_uniqueness_on_db(objects, table, field, row_start, columns=[])
      # Columns is used if you want to test the field against more than the columns with same name.
      # If none passed, we just use the field as the column
      columns << field if columns.empty?
      results = []

      columns.each do |column|
        string_params = generate_string_params_template_with_quotes(objects.length)
        field_values = objects.map{|u| u.send(field.to_sym)}

        #Avoid executing queries if fields aren't present
        unless field_values.all?(&:nil?)
          sql_query_array = ["SELECT #{field} FROM #{table} WHERE #{column} IN (#{string_params})", field_values].flatten

          results = execute_sql_query_array(sql_query_array).entries
        end
      end

      results
    end

    def generate_string_params_template_with_quotes(length)
      Array.new(length){'%s'}.map{|p| "'#{p}'" }.join(',')
    end

    def generate_string_params_template(length)
      Array.new(length){'%s'}.join(', ')
    end

    def convert_values_to_insert_syntax(object)
      object.attributes.map do |k, v|
        if v.is_a?(String)
          "'#{v}'"
        elsif (k == "created_at" || k == "updated_at")
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
end
