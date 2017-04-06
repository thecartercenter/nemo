# Keeps track of all the objects created during a replication operation.
class Replication::History
  attr_accessor :table

  def initialize
    self.table = {}
  end

  def add_pair(orig, copy)
    puts "ADDING PAIR [#{orig.klass.name}, #{orig.id}]"
    table[[orig.klass.name, orig.id]] = copy
  end

  def get_copy(klass, id)
    puts "GETTING PAIR [#{klass.name}, #{id}]"
    puts "TABLE:"
    puts "#{table.awesome_inspect}"
    raise "ID not given for history lookup" if id.blank?
    table[[klass.name, id]]
  end
end
