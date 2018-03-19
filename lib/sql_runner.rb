class SqlRunner
  include Singleton

  # Runs query and returns hash of results. Accepts the usual sanitize argument scheme.
  def run(*args, type_map: true)
    result = connection.execute(sanitize(*args))
    result.type_map = type_map if type_map
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
