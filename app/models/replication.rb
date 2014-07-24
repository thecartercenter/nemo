# Models a recursive replication operation.
# Holds all internal parameters used during the operation
class Replication
  attr_accessor :dest_mission, :parent_assoc, :in_transaction, :current_assoc, :ancestors, :deep_copy,
    :recursed, :src_obj, :dest_obj, :mode, :retain_link_on_promote

  alias_method :retain_link_on_promote?, :retain_link_on_promote
  alias_method :deep_copy?, :deep_copy
  alias_method :recursed?, :recursed
  alias_method :in_transaction?, :in_transaction

  def initialize(params)
    # copy all params
    params.each{|k,v| instance_variable_set("@#{k}", v)}

    self.ancestors ||= []

    self.dest_mission = src_obj.mission if clone?

    # determine whether deep or shallow, unless already set
    # by default, we do a deep copy iff we're copying to a different mission
    self.deep_copy ||= src_obj.mission != dest_mission

    # recursed defaults to false, and is set to true explicitly when recursing
    self.recursed ||= false
  end

  # calls replication from within a transaction and returns result
  # sets in_transaction flag to true
  def redo_in_transaction
    self.in_transaction = true
    ActiveRecord::Base.transaction { src_obj.replicate(self) }
  end

  # creates a clone of the current replication for a recursive call
  # child - the child object on which the call is being done
  # association - the name of the association to which the child belongs
  def clone_for_recursion(child, association)
    self.class.new(
      # replication mode
      :mode => mode,

      # the new src_obj is of course the child
      :src_obj => child,

      # these stay the same
      :dest_mission => dest_mission,
      :deep_copy => deep_copy,
      :retain_link_on_promote => retain_link_on_promote,

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

  def clone?
    mode == :clone
  end

  def to_mission?
    mode == :to_mission
  end

  def promote?
    mode == :promote
  end

  def promote_and_retain_link?
    promote? && retain_link_on_promote?
  end

  def to_standard?
    promote? || clone? && dest_mission.nil?
  end

  def shallow_copy?
    !deep_copy
  end

  def has_ancestors?
    !ancestors.empty?
  end

  def has_dest_mission?
    !dest_mission.nil?
  end

  # returns the immediate parent obj of this replication
  # may be nil
  def parent
    ancestors.last
  end

  # returns whether we are creating or updating the dest obj
  def creating?
    dest_obj.new_record?
  end

  # returns a string representation used for logging
  def to_s
    [].tap do |lines|
      lines << "***** REPLICATING *******************************************************************"
      lines << "mode:         #{mode}"
      lines << "Source obj:   #{src_obj}"
      lines << "Dest mission: #{dest_mission || '[nil]'}"
    end.join("\n")
  end
end

