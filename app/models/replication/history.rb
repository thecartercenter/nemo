# frozen_string_literal: true

# Keeps track of all the objects created during a replication operation.
class Replication::History
  attr_accessor :table

  def initialize
    self.table = {}
  end

  def add_pair(orig, copy)
    # We don't need to track class name anymore since we're using UUIDs.
    # Tracking class name is tricky in the case of inheritance anyway.
    table[orig.id] = copy
  end

  def get_copy(id)
    raise "ID not given for history lookup" if id.blank?
    table[id]
  end
end
