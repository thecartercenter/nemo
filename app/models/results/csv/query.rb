# frozen_string_literal: true

module Results
  module Csv
    # Abstract class modeling a database query.
    class Query
      UUID_LENGTH = 36 # This should never change.

      def run
        set_db_timezone do
          # The type map is very slow and we don't need it since we're outputting strings.
          SqlRunner.instance.run("#{select} #{from} #{where} #{order}", use_type_map: false)
        end
      end

      protected

      def translation_query(column, arr_index: nil)
        arr_op = arr_index && "->(#{arr_index})"
        tries = configatron.preferred_locales.map do |locale|
          "#{column}#{arr_op}->>'#{locale}'"
        end
        "COALESCE(#{tries.uniq.join(', ')})"
      end

      # Sets the DB's timezone to the current one so that the response times are shown with a timezone
      # offset. This is faster than doing it in Ruby.
      def set_db_timezone
        SqlRunner.instance.run("SET SESSION TIME ZONE INTERVAL '#{Time.zone.formatted_offset}'")
        yield
      ensure
        # The DB should generally be in UTC zone. Rails handles conversions internally.
        SqlRunner.instance.run("SET SESSION TIME ZONE 'UTC'")
      end

      def answer_type_and_not_deleted
        <<~SQL
          responses.deleted_at IS NULL
          AND answers.deleted_at IS NULL
          AND answers.type = 'Answer'
        SQL
      end
    end
  end
end
