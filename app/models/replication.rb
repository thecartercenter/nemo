# models a recursive replication operation
# holds all internal parameters used during the operation
class Replication
  attr_accessor :to_mission, :parent_assoc, :in_transaction

  def initialize(params)
    # copy all params
    params.each{|k,v| instance_variable_set("@#{k}", v)}

    # to_mission should default to obj's mission if nil
    # this would imply a within-mission clone
    @to_mission ||= @obj.mission
  end

  # calls replication from within a transaction and returns result
  # sets in_transaction flag to true
  def redo_in_transaction
    @in_transaction = true
    return ActiveRecord::Base.transaction do
      @obj.replicate(to_mission, self)
    end
  end

  # propagates the replication to the given child object
  # creates a new replication object for that stage of the replication
  def recurse_to(child, *args)
    new_replication = self.class.new(
      :obj => child, 
      :to_mission => to_mission,
      :in_transaction => true)

    child.replicate(to_mission, new_replication, *args)
  end

  # accessor for better readability
  def in_transaction?
    !!in_transaction
  end
end