# frozen_string_literal: true

class Replication::BackwardAssocError < Replication::Error
  attr_accessor :ok_to_skip
end
