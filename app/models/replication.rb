# models a recursive replication operation
# holds all internal parameters used during the operation
class Replication
  attr_accessor :to_mission, :parent_assoc, :in_transaction,
    :current_assoc, :ancestors, :deep_copy,
    :recursed, :src_obj, :dest_obj, :link_to_standard,
    :mode # there are two modes 1) promote and 2) default.
          # promote: take an mission based object and clones it as a standard object
          # TOM: same thing here. why not have 3 modes (promote, clone, to_mission) and make everything simpler and clearer
          # default: use the mission value to determine if we are cloning to a standard or mission.
          # TOM: i don't get this last part. how can mode be ':mission => m'? the mission should be a separate param of Replication
          #          in the future this will be :clone or :to_mission, :mission => m

          # TOM: we may also want to rename the :to_mission attribute to :dest_mission so as not to confuse it with the :to_mission mode

  def initialize(params)
    # copy all params
    params.each{|k,v| instance_variable_set("@#{k}", v)}

    @to_mission ||= determine_to_mission(@src_obj.mission)

    # ensure ancestors is [] if nil
    @ancestors ||= []

    # determine whether deep or shallow, unless already set
    # by default, we do a deep copy iff we're copying to a different mission
    @deep_copy ||= @src_obj.mission != @to_mission

    # recursed defaults to false, and is set to true explicitly when recursing
    @recursed ||= false
  end

  # TOM: this could also go away
  # determine to_mission value
  # * if we are promoting an object, the target mission is empty/nil
  # * otherwise we default to src_obj's mission
  #
  # if the src_obj mission:
  # * has a value, we are doing a within-mission clone
  # * is nill, this is a standard object being cloned
  def determine_to_mission(src_mission)
    promote? ? nil : src_mission
  end

  # TOM: should there not be similar accessors for other modes? or why not just do replication.mode == :promote
  # are we replicating a mission based object to a standard
  def promote?
    @mode == :promote
  end

  # TOM: rename to 'retain_link_on_promote'?
  # are we replicating a mission based object to a standard and linking to that standard
  # if so, this results in a coordinator being unable to modify the object as it is no long a mission based object.
  def link_to_standard?
    @link_to_standard
  end

  # TOM: i feel that this code should be in Replicable, not Replication.
  # Replication's responsibility is only to hold the properties of the replication operation
  # (except for the redo_in_transaction convenience method)
  # link the src object to the newly created standard object
  def link_object_to_standard(standard_object)
    @src_obj.is_standard = true
    @src_obj.standard_id = standard_object.id
    @src_obj.save!
  end

  # calls replication from within a transaction and returns result
  # sets in_transaction flag to true
  def redo_in_transaction
    @in_transaction = true
    return ActiveRecord::Base.transaction do
      new_obj = @src_obj.replicate(self)

      # TOM: this code also doesn't belong here i think, see reasoning above.
      # link basic object to newly created standard object
      if promote? && link_to_standard?
        link_object_to_standard(new_obj)
      end

      new_obj
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

  # checks if this replication is replicating a standard object to a mission
  def standard_to_mission?
    src_obj.is_standard? && !to_mission.nil?
  end

  # is replication to a standard object. This can be by clone or promotion.
  def replicating_to_standard?
    to_mission.nil?
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
    lines << "mode:         #{mode}"
    lines << "Source obj:   #{src_obj}"
    lines << "Dest mission: #{to_mission || '[nil]'}"
    lines.join("\n")
  end
end

