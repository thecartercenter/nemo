# frozen_string_literal: true

module Results
  module CSV
    # Keeps track of what column index each named header is written to.
    class HeaderMap
      attr_accessor :common_headers, :group_headers, :locales

      def initialize(locales:)
        self.map = ActiveSupport::OrderedHash.new
        self.locales = locales
      end

      def add_common(common_headers)
        self.common_headers = common_headers
        common_headers.each { |h| add(h) }
      end

      def add_group(group_headers)
        self.group_headers = group_headers
        group_headers.each { |h| add(h) }
      end

      # Takes an array of hashes with keys: code, qtype_name, level_names, allow_coordinates.
      # Array is sorted by code.
      # Adds appropriate headers.
      def add_from_qcodes(rows)
        rows.each do |row|
          if row["qtype_name"] == "location"
            add_location_headers(row["code"])
          else
            add_from_qcode(row)
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

      attr_accessor :map

      def common_or_group?(header)
        common_headers.include?(header) || group_headers.include?(header)
      end

      def translate(header)
        I18n.t("response.csv_headers.#{header}")
      end

      def add_from_qcode(row)
        if row["level_names"]
          add_level_headers(row["code"], row["level_names"])
        else
          add(row["code"])
        end

        # If it's a select question that has coords, add cols for that.
        return unless row["allow_coordinates"] && row["qtype_name"] != "select_multiple"
        add_location_headers(row["code"], lat_lng_only: true)
      end

      def add_location_headers(code, lat_lng_only: false)
        to_add = %i[latitude longitude]
        to_add.concat(%i[altitude accuracy].freeze) unless lat_lng_only
        to_add.each { |h| add(code, suffix: translate(h)) }
      end

      def add_level_headers(code, level_names)
        JSON.parse(level_names).each do |level|
          # Check every locale, starting with user preference, to see where the level has a real name defined.
          key = ([I18n.locale] + locales).detect { |l| level[l.to_s].present? } || level.keys.first
          add(code, suffix: level[key.to_s])
        end
      end

      # Adds a header to the map.
      def add(header, suffix: nil)
        map[[header, suffix].compact.join(":")] ||= map.size
      end
    end
  end
end
