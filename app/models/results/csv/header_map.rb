# frozen_string_literal: true

module Results
  module Csv
    # Keeps track of what column index each named header is written to.
    class HeaderMap
      attr_accessor :map, :common

      def initialize
        self.map = ActiveSupport::OrderedHash.new
      end

      def add_common(common)
        self.common = common
        common.each { |h| add(h) }
      end

      def add_group(max_depth)
        (1..max_depth).to_a.each do |i|
          add("group#{i}_rank")
          add("group#{i}_inst_num")
        end
      end

      # Takes an array of hashes with keys: code, qtype_name, level_names, allow_coordinates.
      # Array is sorted by code.
      # Adds appropriate headers.
      def add_codes(rows)
        rows.each do |row|
          if row["qtype_name"] == "location"
            add_location_headers(row["code"])
          else
            if row["level_names"]
              add_level_headers(row["code"], row["level_names"])
            else
              add(row["code"])
            end

            # If it's a select question that has coords, add cols for that.
            if row["allow_coordinates"] == "t" && row["qtype_name"] != "select_multiple"
              add_location_headers(row["code"], lat_lng_only: true)
            end
          end
        end
      end

      def add(header, suffix: nil)
        index_for([header, suffix].compact.join(":"))
      end

      # Returns the index the given header maps to.
      # If the header doesn't exist yet, adds it.
      def index_for(header)
        map[header] ||= map.size
      end

      def headers
        map.keys
      end

      private

      def add_location_headers(code, lat_lng_only: false)
        to_add = %i[latitude longitude]
        to_add.concat(%i[altitude accuracy].freeze) unless lat_lng_only
        to_add.each do |c|
          add(code, suffix: I18n.t("response.csv_headers.#{c}"))
        end
      end

      def add_level_headers(code, level_names)
        JSON.parse(level_names).each do |level|
          key = configatron.preferred_locales.detect { |l| level[l.to_s].present? } || level.keys.first
          add(code, suffix: level[key.to_s])
        end
      end
    end
  end
end
