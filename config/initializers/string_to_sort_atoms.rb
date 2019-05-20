# From https://makandracards.com/makandra/9185-ruby-natural-sort-strings-with-umlauts-and-other-funny-characters
# Copyright (c) 2012-2019 makandra GmbH, provided under the MIT License.
class SmartSortAtom
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def <=>(other)
    other.is_a?(self.class) or raise "Can only smart compare with other SmartSortAtom"
    left_value = value
    right_value = other.value
    if left_value.class == right_value.class
      left_value <=> right_value
    elsif left_value.is_a?(Float)
      -1
    else
      1
    end
  end

  def self.parse(string)
    # Loosely based on http://stackoverflow.com/a/4079031
    string.scan(/[^\d\.]+|[\d\.]+/).collect do |atom|
      if atom.match(/\d+(\.\d+)?/)
        atom = atom.to_f
      else
        atom = normalize_string(atom)
      end
      new(atom)
    end

  end

  private

  def self.normalize_string(string)
    string = ActiveSupport::Inflector.transliterate(string)
    string = string.downcase
    string
  end
end

String.class_eval do
  def to_sort_atoms
    SmartSortAtom.parse(self)
  end
end
