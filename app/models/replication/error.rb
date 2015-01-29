class Replication::Error < StandardError
end

class Replication::BackwardAssocError < Replication::Error
  attr_accessor :ok_to_skip
end
