# frozen_string_literal: true

# Caches object attributes based on the objects' IDs.
# Works with any number of objects of any class.
# Useful for cases where a lot of copies of a given object
# end up in memory, making memoization problematic.
class AttribCache
  def initialize
    self.table = {}
  end

  def [](object, attrib)
    subtable = table[object.class] ||= {}
    if subtable.key?(object.id)
      subtable[object.id]
    else
      subtable[object.id] = object.send(attrib)
    end
  end

  private

  attr_accessor :table
end
