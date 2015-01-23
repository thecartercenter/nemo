# Keeps track of all the objects created during a replication operation.
class Replication::History
  attr_accessor :table

  def initialize
    self.table = {}
  end

  def add_pair(orig, copy)
    table[[orig.klass, orig.id]] = copy
  end

  def get_copy(klass, id)
    raise "ID not given for history lookup" if id.blank?
    table[[klass, id]]
  end
end
