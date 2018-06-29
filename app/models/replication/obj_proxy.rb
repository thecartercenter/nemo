# Wraps an object in a replication operation. Not the full object, just its ID and class.
class Replication::ObjProxy
  attr_accessor :klass, :id, :ancestry, :replicator, :replication_root
  alias_method :replication_root?, :replication_root

  delegate :child_assocs, to: :klass

  def initialize(attribs)
    raise "No ID given" unless attribs[:id] || attribs["id"]
    raise "No klass given" unless attribs[:klass] || attribs["klass"]
    attribs.each { |k,v| instance_variable_set("@#{k}", v) }
  end

  def inspect
    "<ObjProxy: klass=#{klass.name}, id=#{id}, id_class=#{id.class}, ancestry=#{ancestry}>"
  end

  # Loads the full ActiveRecord object proxied by this one.
  def full_object
    @full_object ||= klass.find(id)
  end

  # Associates this obj with the given obj on the given association.
  # The assoc must be a belongs_to or this won't make sense.
  def associate(assoc, obj)
    # We use update_all so we won't have to load the full object.
    klass.where("id = '#{id}'").update_all("#{assoc.foreign_key} = '#{obj.id}'")
  end

  # assoc - A Replication::AssocProxy representing the association from which to return children.
  # Returns an array of Objs matching the association.
  def children(assoc)
    # Retrieve the id (and ancestry, if applicable) of the orig children objects.
    attribs = if assoc.belongs_to?
      fk_id = klass.where(id: id).pluck(assoc.foreign_key).first
      fk_id ? [self.class.new(id: fk_id, klass: assoc.target_class, replicator: replicator)] : []
    elsif assoc.ancestry?
      child_ancestry = [ancestry, id].compact.join("/")
      build_from_sql("ancestry = '#{child_ancestry}'", target_klass: assoc.target_class, order: "ORDER BY rank")
    else # has_one or has_many
      build_from_sql("#{assoc.foreign_key} = '#{id}'", target_klass: assoc.target_class)
    end
  end

  # Looks for and returns a matching copy of this obj in the context of the current replicator.
  # Returns nil if none found.
  def find_copy
    if reusable?
      self
    # If reuse_if_match option is set, we check for a matching item in the dest mission using that column.
    # reuse_col should obviously be indexed.
    elsif reuse_col = klass.replicable_opts[:reuse_if_match]
      build_from_sql("#{eql_sql(:mission_id, replicator.target_mission_id)}
        AND #{reuse_col} = (
          SELECT #{reuse_col}
          FROM #{klass.table_name}
          WHERE #{klass.table_name}.deleted_at IS NULL AND id = '#{id}'
        )
      ").first
    # If klass is standardizable, we can look for matching using original_id
    elsif klass.standardizable?
      build_from_sql("original_id = '#{id}' AND #{eql_sql(:mission_id, replicator.target_mission_id)}").first
    end
  end

  # Makes a copy of this obj in the database according to replication options and the given replicator.
  def make_copy(context)
    # The mappings variable will hold a set of 2-element arrays, or strings.
    # These values describe how the existing object should be copied to the new one.
    # If value is a string, copy it verbatim. Else the values are SQL expressions
    # representing the col name and new value, respectively.

    # First add the cols to be copied verbatim.
    mappings = klass.attribs_to_replicate

    # But don't copy verbatim columns that need to stay unique.
    mappings.delete(klass.replicable_opts[:uniqueness][:field].to_s) if klass.replicable_opts[:uniqueness]

    # Now add the non-trivial mappings.
    mappings += date_col_mappings(replicator, context)
    mappings += unique_col_mappings(replicator, context)
    mappings += standardizable_col_mappings(replicator, context)
    mappings += backward_assoc_col_mappings(replicator, context)

    if klass.has_ancestry?
      new_ancestry = get_copy_ancestry(context)
      mappings << ["ancestry", new_ancestry.nil? ? nil : quote_or_null(new_ancestry)]
    else
      new_ancestry = nil
    end
    new_id = do_insert(mappings)

    self.class.new(klass: klass, id: new_id, ancestry: new_ancestry, replicator: replicator)
  end

  # Some backward associations may be unknowable during first pass. So we fix them on the second pass.
  def fix_backward_assocs_on_copy(context)
    if klass.second_pass_backward_assocs.any?
      mappings = backward_assoc_col_mappings(replicator, context, second_pass: true)
      replicator.log("Fixing backward associations on #{context[:copy].id}")
      assignments = mappings.map { |m| "#{m[0]} = #{m[1]}" }.join(",")
      sql = "UPDATE #{klass.table_name} SET #{assignments} WHERE id = '#{context[:copy].id}'"
      db.execute(sql)
    end
  end

  protected

  # If replication mode is clone and object is standardizable, we can reuse this object.
  # This is because we always want to reuse standardizable
  # objects when cloning, since clone is shallow operation.
  # The only standardizable object we don't want to reuse is the one at the top of the tree (root).
  def reusable?
    !replication_root? && replicator.mode == :clone && klass.standardizable?
  end

  private

  def db
    klass.connection
  end

  # Given an SQL condition, builds a set of Objs with data resulting from that condition.
  # options[:target_klass] - The class of the new Objs. Defaults to self.klass.
  # options[:order] - An option ORDER BY clause.
  def build_from_sql(condition, options = {})
    options[:target_klass] ||= klass
    get_target_class_from_type_col = options[:target_klass].column_names.include?("type")

    cols = [:id]
    cols << :ancestry if options[:target_klass].has_ancestry?
    cols << :type if get_target_class_from_type_col
    data = db.select_all("
      SELECT #{concat(cols)}
      FROM #{options[:target_klass].table_name}
      WHERE #{options[:target_klass].table_name}.deleted_at IS NULL
        AND #{condition} #{options[:order]}
    ")

    data.map do |attribs|
      attribs["id"] = attribs["id"]
      tc = get_target_class_from_type_col ? attribs.delete("type").constantize : options[:target_klass]
      self.class.new(attribs.merge(klass: tc, replicator: replicator))
    end
  end

  # Generates an equality expression in SQL, respecting NULL.
  def eql_sql(col, value)
    value.nil? ? "#{col} IS NULL" : "#{col} = '#{value}'"
  end

  def get_copy_ancestry(context)
    # If self is a root node (ancestry == nil) then we just copy nil.
    # Else we construct the ancestry by looking at that of the copy_parent.
    if ancestry.nil?
      nil
    else
      # We combine the copy parent's own ancestry (which may be nil) plus its ID.
      joined = [context[:copy_parent].ancestry, context[:copy_parent].id].compact.join("/")
      joined.blank? ? nil : joined
    end
  end

  def date_col_mappings(replicator, context)
    [["created_at", "NOW()"], ["updated_at", "NOW()"]]
  end

  def unique_col_mappings(replicator, context)
    return [] unless uniq_spec = klass.replicable_opts[:uniqueness]
    generator = Replication::UniqueFieldGenerator.new(
      uniq_spec.merge(klass: klass, orig_id: id, mission_id: replicator.target_mission_id))
    [[uniq_spec[:field], ApplicationRecord.connection.quote(generator.generate)]]
  end

  def standardizable_col_mappings(replicator, context)
    mappings = []
    case replicator.mode
    when :promote
      mappings << ["is_standard", true] if klass.standardizable?
    when :clone
      mappings << "mission_id"
      mappings << "is_standard" if klass.standardizable?
    when :to_mission
      mappings << ["mission_id", quote_or_null(replicator.target_mission_id)]
      mappings << ["standard_copy", true] if klass.standardizable? && replicator.source_is_standard?
    end
    mappings << ["original_id", "id"] if klass.standardizable?
    mappings
  end

  # Returns column mappings for backward associations.
  # If second_pass is true, it means we only want second pass-type backward associations.
  # Otherwise, we want all of them.
  def backward_assoc_col_mappings(replicator, context, second_pass: false)
    assocs = second_pass ? klass.second_pass_backward_assocs : klass.backward_assocs
    assocs.map do |assoc|
      begin
        [assoc.foreign_key, quote_or_null(backward_assoc_id(replicator, context, assoc))]
      rescue Replication::BackwardAssocError
        # If we have explicit instructions to delete the object if an association is missing, make a note of it.
        $!.ok_to_skip = assoc.skip_obj_if_missing
        raise $! # Then we send on up the chain.
      end
    end
  end

  def backward_assoc_id(replicator, context, assoc)
    orig_foreign_id = klass.where(id: id).pluck(assoc.foreign_key).first
    if orig_foreign_id.nil?
      replicator.log("Original foreign ID for backward assoc #{assoc.name} is NULL, skipping")
      return nil
    end

    # If it's the first pass but the association specifies second pass, we shouldn't try to find the
    # associated copy, because it might not exist yet.
    if replicator.first_pass? && assoc.second_pass?
      replicator.log("Not attempting to locate backward associated object in first pass for #{assoc.name}")
      # If `temp_id` is set to something, it means we still need to set the foreign
      # key, maybe because there a null constraint.
      # We call the temp_id Proc and pass the copy_parent obj.
      if assoc.temp_id.present?
        foreign_id = assoc.temp_id.call(context[:copy_parent].full_object)
        replicator.log("Using temp ID #{foreign_id} instead")
        foreign_id
      else
        replicator.log("Leaving association as NULL for now")
        nil
      end
    else
      target_class = if assoc.polymorphic?
        klass.where(id: id).pluck(assoc.foreign_type).first.constantize
      else
        assoc.target_class
      end
      get_copy_id(target_class, orig_foreign_id) ||
        (raise Replication::BackwardAssocError.new("
          Couldn't find copy of #{target_class.name} ##{orig_foreign_id}"))
    end
  end

  def get_copy_id(target_class, orig_id)
    # Try to find the appropriate copy in the replicator history
    if history_copy = replicator.history.get_copy(orig_id)
      history_copy.id

    # Reuse original if it's reusable.
    elsif self.class.new(klass: target_class, id: orig_id, replicator: replicator).reusable?
      orig_id

    # Use reuse_if_match if defined (this will eventually go away when we get rid of Option)
    elsif reuse_col = target_class.replicable_opts[:reuse_if_match]
      orig_reuse_val = target_class.where(id: orig_id).pluck(reuse_col).first
      target_class.where(mission_id: replicator.target_mission_id, reuse_col => orig_reuse_val).first.try(:id)

    # Else try looking up original_id if available
    elsif target_class.standardizable?
      copies_in_mission = target_class.where(mission_id: replicator.target_mission_id, original_id: orig_id)
      copies_in_mission.any? ? copies_in_mission.first.id : nil
    else
      nil
    end
  end

  def do_insert(mappings)
    insert_cols = concat(mappings.map { |s| s.is_a?(Array) ? s[0] : s })
    select_chunks = concat(mappings.map { |s| s.is_a?(Array) ? s[1] : s })

    sql = "INSERT INTO #{klass.table_name} (#{insert_cols})
      SELECT #{select_chunks} FROM #{klass.table_name} WHERE id = '#{id}'"

    db.insert(sql)
  end

  def concat(exprs)
    exprs.map do |expr|
      case expr
      when "default" then '"default"'
      when nil then "NULL"
      else expr
      end
    end.join(",")
  end

  def quote_or_null(id)
    id.nil? ? "NULL" : "'#{id}'"
  end
end
