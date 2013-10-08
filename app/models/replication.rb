# models a recursive replication operation
# holds all internal parameters used during the operation
class Replication
  attr_accessor :to_mission, :parent_assoc

  def initialize(params)
    # copy all params
    params.each{|k,v| instance_variable_set("@#{k}", v)}

    # to_mission should default to obj's mission if nil
    # this would imply a within-mission clone
    @to_mission ||= @obj.mission
  end

  # propagates the replication to the given child object
  # creates a new replication object for that stage of the replication
  def recurse_to(child, *args)
    new_replication = self.class.new(:obj => child, :to_mission => to_mission)
    child.replicate(to_mission, new_replication, *args)
  end
end