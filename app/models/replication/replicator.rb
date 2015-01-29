# Handles copying of objects between missions and to/from standards.
class Replication::Replicator
  attr_accessor :source, :mode, :dest_mission, :history

  # options[:source] - The root object to be replicated.
  # options[:mode] - See Replication::Replicable concern for documentation.
  # options[:dest_mission] - See Replication::Replicable concern for documentation.
  def initialize(attribs)
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
    self.history = Replication::History.new
  end

  def replicate
    source.class.transaction do
      obj = Replication::ObjProxy.new(klass: source.class, id: source.id, replicator: self) # Create wrapper
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
    source.is_standard?
  end

  def log(msg)
    Rails.logger.debug("REPLICATION: #{msg}") if Rails.env.development? || Rails.env.test?
  end

  private

    # context[:orig] - The Obj to be replicated.
    # context[:orig_parent] - The parent Obj of the Obj to be replicated.
    # context[:copy_parent] - The copy of the parent of the Obj to be replicated.
    # Returns the copy Replication::ObjProxy.
    def do_replicate(context)
      log("Object: #{context[:orig].klass.name}")
      begin
        context[:copy] = context[:orig].make_copy(context)
        history.add_pair(context[:orig], context[:copy])
        replicate_children(context)
        context[:copy]
      rescue Replication::BackwardAssocError
        # If it's explicitly ok to skip this object, do so, else raise again so this will fail loudly.
        $!.ok_to_skip ? nil : (raise $!)
      end
    end

    def replicate_children(context)
      log("Child assocs: #{context[:orig].child_assocs.map(&:name)}")
      context[:orig].child_assocs.each do |assoc|
        log("Assoc: #{assoc.name}")
        copy_child = nil
        context[:orig].children(assoc).map do |child|
          log("Child: ##{child.id}")
          # Try to find an existing copy. If one doesn't exist, make one.
          unless copy_child = child.find_copy
            copy_child = do_replicate(orig: child, orig_parent: context[:orig], copy_parent: context[:copy])
          end
        end

        # If the assoc is belongs_to, the foreign key couldn't be set during make_copy.
        # So we set it now. (Note can only be one child for this association)
        if assoc.belongs_to? && copy_child
          context[:copy].associate(assoc, copy_child)
        end
      end
    end
  end
