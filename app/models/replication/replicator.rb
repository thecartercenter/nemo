# frozen_string_literal: true

# Handles copying of objects between missions and to/from standards.
class Replication::Replicator
  attr_accessor :source, :mode, :dest_mission, :history, :pass_num

  # options[:source] - The root object to be replicated.
  # options[:mode] - See Replication::Replicable concern for documentation.
  # options[:dest_mission] - See Replication::Replicable concern for documentation.
  def initialize(attribs)
    attribs.each { |k, v| instance_variable_set("@#{k}", v) }
    self.history = Replication::History.new
    self.pass_num = 1
  end

  def replicate
    source.class.transaction do
      # Create wrapper
      obj = Replication::ObjProxy.new(klass: source.class, id: source.id,
                                      replicator: self, replication_root: true)
      do_replicate(orig: obj)
      self.pass_num = 2
      do_replicate(orig: obj).full_object
    end
  end

  def target_mission_id
    case mode
    when :clone then source.mission_id
    when :to_mission then dest_mission.id
    when :promote then nil
    end
  end

  def source_is_standard?
    source.standard?
  end

  def log(msg)
    Rails.logger.debug("REPLICATION [PASS #{pass_num}]: #{msg}") if Rails.env.development? || Rails.env.test?
  end

  def first_pass?
    pass_num == 1
  end

  def second_pass?
    pass_num == 2
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

  private

  # context[:orig] - The Obj to be replicated.
  # context[:orig_parent] - The parent Obj of the Obj to be replicated.
  # context[:copy_parent] - The copy of the parent of the Obj to be replicated.
  # Returns the copy Replication::ObjProxy.
  def do_replicate(context)
    log("Object: #{context[:orig].klass.name}")
    begin
      if first_pass?
        log("Making copy")
        context[:copy] = context[:orig].make_copy(context)
        history.add_pair(context[:orig], context[:copy])
      else
        context[:copy] = history.get_copy(context[:orig].id)
        # Copy may not exist if e.g. it was skipped due to skip_obj_if_missing param.
        context[:orig].fix_backward_assocs_on_copy(context) if context[:copy]
      end
      replicate_children(context)
      context[:copy]
    rescue Replication::BackwardAssocError
      # If it's explicitly ok to skip this object, do so, else raise again so this will fail loudly.
      raise $ERROR_INFO unless $ERROR_INFO.ok_to_skip
      log("Backward association missing (#{$ERROR_INFO}), skipping")
    end
  end

  def replicate_children(context)
    log("Child assocs: #{context[:orig].child_assocs.map(&:name)}")
    context[:orig].child_assocs.each do |assoc|
      children = context[:orig].children(assoc)

      log("Replicating #{children.size} children for association #{assoc.name}")

      copy_child = nil
      children.map do |child|
        log("Original Child ID: ##{child.id}")

        # Try to find an existing copy. If one doesn't exist, make one.
        unless (copy_child = child.find_copy)
          copy_child = do_replicate(orig: child, orig_parent: context[:orig], copy_parent: context[:copy])
        end
      end

      # If the assoc is belongs_to, the foreign key couldn't be set during make_copy.
      # So we set it now. (Note can only be one child for this association)
      context[:copy].associate(assoc, copy_child) if first_pass? && assoc.belongs_to? && copy_child
    end
  end
end
