# models a recursive replication operation
# holds all internal parameters used during the operation
class Replication
  attr_accessor :to_mission, :parent_assoc, :in_transaction, :current_assoc, :ancestors, :deep_copy,
    :recursed, :src_obj, :dest_obj

  def initialize(params)
    # copy all params
    params.each{|k,v| instance_variable_set("@#{k}", v)}

    # to_mission should default to src_obj's mission if nil
    # this would imply a within-mission clone
    # if the src object's mission is also nil, then this is a standard object being cloned
    @to_mission ||= @src_obj.mission

    # ensure ancestors is [] if nil
    @ancestors ||= []

    # determine whether deep or shallow, unless already set
    # by default, we do a deep copy iff we're copying to a different mission
    @deep_copy ||= @src_obj.mission != @to_mission

    # recursed defaults to false, and is set to true explicitly when recursing
    @recursed ||= false
  end

  # calls replication from within a transaction and returns result
  # sets in_transaction flag to true
  def redo_in_transaction
    @in_transaction = true
    return ActiveRecord::Base.transaction do
      @src_obj.replicate(self)
    end
  end

  # creates a clone of the current replication for a recursive call
  # child - the child object on which the call is being done
  # association - the name of the association to which the child belongs
  def clone_for_recursion(child, association)
    self.class.new(
      # the new src_obj is of course the child
      :src_obj => child,

      # these stay the same
      :to_mission => to_mission,
      :deep_copy => deep_copy,

      # this is always true since we go into a transaction first thing
      :in_transaction => true,

      # the current_assoc is the name of the association that is currently being replicated
      :current_assoc => association,

      # add the new copy to the list of copy parents
      :ancestors => ancestors + [dest_obj],

      # recursed always is true since we're recursing here
      :recursed => true
    )
  end

  # checks if this replication is replicating a standard object to another standard object
  def standard_to_standard?
    src_obj.is_standard? && to_mission.nil?
  end

  # accessor for better readability
  def in_transaction?
    !!in_transaction
  end

  # accessor for better readability
  def deep_copy?
    deep_copy
  end

  def shallow_copy?
    !deep_copy
  end

  def has_ancestors?
    !ancestors.empty?
  end

  def has_to_mission?
    !to_mission.nil?
  end

  # returns the immediate parent obj of this replication
  # may be nil
  def parent
    ancestors.last
  end

  def recursed?
    recursed
  end

  # returns whether we are creating or updating the dest obj
  def creating?
    dest_obj.new_record?
  end

  # returns a string representation used for logging
  def to_s
    lines = []
    lines << "***** REPLICATING *******************************************************************"
    lines << "Source obj:   #{src_obj}"
    lines << "Dest mission: #{to_mission || '[nil]'}"
    lines.join("\n")
  end
end