# frozen_string_literal: true

# From https://makandracards.com/makandra/9185-ruby-natural-sort-strings-with-umlauts-and-other-funny-characters
# Copyright (c) 2012-2019 makandra GmbH, provided under the MIT License.
module Enumerable
  # Sorts intuitively; understands special characters and numeric ordering.
  def natural_sort
    natural_sort_by
  end

  # Sorts intuitively; understands special characters and numeric ordering.
  def natural_sort_by(&stringifier)
    sort_by do |element|
      element = yield(element) if stringifier
      element = element.to_s unless element.respond_to?(:to_sort_atoms)
      element.to_sort_atoms
    end
  end

  # Natural-sorts a list of hashes by item key.
  def natural_sort_by_key(key = :name)
    sort do |x, y|
      x_value = x[key]
      x_value = x_value.to_s unless x_value.respond_to?(:to_sort_atoms)

      y_value = y[key]
      y_value = y_value.to_s unless y_value.respond_to?(:to_sort_atoms)

      x_value.to_sort_atoms <=> y_value.to_sort_atoms
    end
  end
end
