# models a recursive replication operation
# holds all internal parameters used during the operation
class Replication
  attr_accessor :to_mission, :parent_assoc, :in_transaction, :current_assoc, :ancestors, :deep_copy, :recursed

  def initialize(params)
    # copy all params
    params.each{|k,v| instance_variable_set("@#{k}", v)}

    # to_mission should default to obj's mission if nil
    # this would imply a within-mission clone
    @to_mission ||= @obj.mission

    # ensure ancestors is [] if nil
    @ancestors ||= []

    # determine whether deep or shallow, unless already set
    # by default, we do a deep copy iff we're copying to a different mission
    @deep_copy ||= @obj.mission != @to_mission

    # recursed defaults to false, and is set to true explicitly when recursing
    @recursed ||= false
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
  # association is the name of the association that we are recursing to
  def recurse_to(child, association, copy, *args)
    new_replication = self.class.new(
      # the new obj is of course the child
      :obj => child, 

      # these stay the same
      :to_mission => to_mission,
      :deep_copy => deep_copy,

      # this is always true since we go into a transaction first thing
      :in_transaction => true,

      # the current_assoc is the name of the association that is currently being replicated
      :current_assoc => association,

      # add the new copy to the list of copy parents
      :ancestors => ancestors + [copy],

      # recursed always is true since we're recursing here
      :recursed => true
    )

    child.replicate(to_mission, new_replication, *args)
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

  # returns the immediate parent obj of this replication
  # may be nil
  def parent
    ancestors.last
  end

  def recursed?
    recursed
  end
end