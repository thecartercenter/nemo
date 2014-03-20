# models a recursive replication operation
# holds all internal parameters used during the operation
class Replication
  attr_accessor :dest_mission, :parent_assoc, :in_transaction,
    :current_assoc, :ancestors, :deep_copy,
    :recursed, :src_obj, :dest_obj,
    :mode, # there are three modes
           # * clone:      make a copy of the object and its decendents.
           #               the mission for the clones is the same as the original objects mission.
           # * to_mission: make a copy of the object and its decendents under a different mission.
           #               requires an additional parameter: :to_mission
           # * promote:    take an mission based object and clones it as a standard object
    :retain_link_on_promote  # when in promote mode, do we link the original object to the new standard object?
                             # if so, a coordinator will be unable to modify the object as it is no long a mission based object.

  alias_method :retain_link_on_promote?, :retain_link_on_promote
  alias_method :deep_copy?, :deep_copy
  alias_method :recursed?, :recursed

  def initialize(params)
    # copy all params
    params.each{|k,v| instance_variable_set("@#{k}", v)}

    raise ArgumentError, 'replication mode has not been selected' if @mode.nil?

    determine_dest_mission

    # ensure ancestors is [] if nil
    @ancestors ||= []

    # determine whether deep or shallow, unless already set
    # by default, we do a deep copy iff we're copying to a different mission
    @deep_copy ||= @src_obj.mission != @dest_mission

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

  # checks if this replication is replicating a standard object to a mission
  def standard_to_mission?
    src_obj.is_standard? && !dest_mission.nil?
  end

  # is replication to a standard object. This can be by clone or promotion.
  def replicating_to_standard?
    dest_mission.nil?
  end

  # accessor for better readability
  def in_transaction?
    !!in_transaction
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
    lines = []
    lines << "***** REPLICATING *******************************************************************"
    lines << "mode:         #{mode}"
    lines << "Source obj:   #{src_obj}"
    lines << "Dest mission: #{dest_mission || '[nil]'}"
    lines.join("\n")
  end

  private

    # determine and store the dest_mission value
    # * if we are in promte mode, the target mission is empty/nil
    # * if the mission is passed in, we are copying to a mission
    # * if the mission is not passed in, we are cloning to the src_obj's mission
    def determine_dest_mission
      if @mode == :promote
        @dest_mission = nil
      else
        @dest_mission ||= @src_obj.mission
      end
    end
end

