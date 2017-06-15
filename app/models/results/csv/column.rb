module Results
  module Csv
    class Column
      include CSVHelper, Comparable
      attr_accessor :code, :name, :position

      def initialize(code: nil, name: nil, position: nil)
        @code = code
        @name = Array.wrap(name).join(":").gsub(/[^a-z0-9:]/i, '')
        @position = position
      end

      def to_s
        format_csv_para_text(name)
      end

      def inspect
        "#{@position}: #{@code} - #{@name}"
      end
    end
  end
end
