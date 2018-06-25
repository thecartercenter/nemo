# frozen_string_literal: true

module Results
  module Csv
    # Keeps track of what column index each named header is written to.
    class HeaderMap
      attr_accessor :map, :common_headers, :group_headers

      def initialize
        self.map = ActiveSupport::OrderedHash.new
      end

      def add_common_headers(common_headers)
        self.common_headers = common_headers
        common_headers.each { |h| add(h) }
      end

      def add_group_headers(max_depth)
        self.group_headers = []
        (1..max_depth).to_a.each do |i|
          add_group_header("group#{i}_rank")
          add_group_header("group#{i}_inst_num")
        end
        add_group_header("parent_group_name")
        add_group_header("parent_group_depth")
      end

      # Takes an array of hashes with keys: code, qtype_name, level_names, allow_coordinates.
      # Array is sorted by code.
      # Adds appropriate headers.
      def add_headers_from_codes(rows)
        rows.each do |row|
          if row["qtype_name"] == "location"
            add_location_headers(row["code"])
          else
            row["level_names"] ? add_level_headers(row["code"], row["level_names"]) : add(row["code"])

            # If it's a select question that has coords, add cols for that.
            if row["allow_coordinates"] && row["qtype_name"] != "select_multiple"
              add_location_headers(row["code"], lat_lng_only: true)
            end
          end
        end
      end

      # Returns the index the given header maps to, or nil if not found.
      def index_for(header)
        map[header]
      end

      def translated_headers
        map.keys.map { |h| common_or_group?(h) ? translate(h) : h }
      end

      def count
        map.size
      end

      private

      def common_or_group?(header)
        common_headers.include?(header) || group_headers.include?(header)
      end

      def translate(header)
        I18n.t("response.csv_headers.#{header}")
      end

      def add_group_header(header)
        group_headers << header
        add(header)
      end

      def add_location_headers(code, lat_lng_only: false)
        to_add = %i[latitude longitude]
        to_add.concat(%i[altitude accuracy].freeze) unless lat_lng_only
        to_add.each { |h| add(code, suffix: translate(h)) }
      end

      def add_level_headers(code, level_names)
        JSON.parse(level_names).each do |level|
          key = configatron.preferred_locales.detect { |l| level[l.to_s].present? } || level.keys.first
          add(code, suffix: level[key.to_s])
        end
      end

      def add(header, suffix: nil)
        map[[header, suffix].compact.join(":")] ||= map.size
      end
    end
  end
end
