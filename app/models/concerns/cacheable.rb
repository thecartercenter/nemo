# frozen_string_literal: true

# methods that help in generating cache keys
module Cacheable
  extend ActiveSupport::Concern

  included do
    # returns a basic cache key based on the number of records and the last update time
    # options[:rel] - a relation to use instead of .all
    # options[:prefix] - a prefix to use after the class name and before the date and count
    def self.count_and_date_cache_key(options = nil)
      rel = options[:rel] || all

      # add class name
      pieces = [name.downcase]

      # add optional prefix if given
      pieces << options[:prefix] if options[:prefix]

      # add count & last update
      pieces << if rel.empty?
                  "empty"
                else
                  last_update = rel.order("updated_at DESC").first.updated_at.strftime("%Y%m%d%H%M%S")
                  "#{rel.count}-#{last_update}"
                end

      pieces.join("/")
    end
  end
end
