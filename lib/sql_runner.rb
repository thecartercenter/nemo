class SqlRunner
  include Singleton

  # Runs query and returns hash of results. Accepts the usual sanitize argument scheme.
  def run(*args, use_type_map: true, sanitize: true)
    result = connection.execute(sanitize ? sanitize(*args) : args.first)
    result.type_map = type_map if use_type_map
    result
  end

  def sanitize(*args)
    ApplicationRecord.send(:sanitize_sql_array, args)
  end

  private

  def connection
    ApplicationRecord.connection
  end

  def type_map
    @type_map ||= PG::BasicTypeMapForResults.new(connection.raw_connection)
  end
end
