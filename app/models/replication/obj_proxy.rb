# Wraps an object in a replication operation. Not the full object, just its ID and class.
class Replication::ObjProxy
  attr_accessor :klass, :id, :ancestry, :replicator

  delegate :child_assocs, to: :klass

  def initialize(attribs)
    raise 'No ID given' unless attribs[:id] || attribs['id']
    raise 'No klass given' unless attribs[:klass] || attribs['klass']
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

  # Loads the full ActiveRecord object proxied by this one.
  def full_object
    @full_object ||= klass.find(id)
  end

  # Associates this obj with the given obj on the given association.
  # The assoc must be a belongs_to or this won't make sense.
  def associate(assoc, obj)
    # We use update_all so we won't have to load the full object.
    klass.update_all("#{assoc.foreign_key} = #{obj.id}", "id = #{id}")
  end

  # assoc - A Replication::AssocProxy representing the association from which to return children.
  # Returns an array of Objs matching the association.
  def children(assoc)
    # Retrieve the id (and ancestry, if applicable) of the orig children objects.
    attribs = if assoc.belongs_to?
      fk_id = klass.where(id: id).pluck(assoc.foreign_key).first
      fk_id ? [self.class.new(id: fk_id, klass: assoc.target_class, replicator: replicator)] : []
    elsif assoc.ancestry?
      child_ancestry = [ancestry, id].compact.join('/')
      build_from_sql("ancestry = '#{child_ancestry}'", target_klass: assoc.target_class, order: 'ORDER BY rank')
    else # has_one or has_many
      build_from_sql("#{assoc.foreign_key} = #{id}", target_klass: assoc.target_class)
    end
  end

  # Looks for and returns a matching copy of this obj in the context of the current replicator.
  # Returns nil if none found.
  def find_copy
    # If replication mode is clone and object is standardizable, copy is just self!
    # This is because we always want to reuse standardizable objects when cloning, since clone is shallow operation.
    # The only standardizable object we don't want to reuse is the one at the top of the tree,
    # but find_copy is only called when dealing with children.
    if replicator.mode == :clone && klass.standardizable?
      self
    # If reuse_if_match option is set, we check for a matching item in the dest mission using that column.
    # reuse_col should obviously be indexed.
    elsif reuse_col = klass.replicable_opts[:reuse_if_match]
      build_from_sql("#{eql_sql(:mission_id, replicator.target_mission_id)}
        AND #{reuse_col} = (SELECT #{reuse_col} FROM #{klass.table_name} WHERE id = #{id})").first
    # If klass is standardizable, we can look for matching using original_id
    elsif klass.standardizable?
      build_from_sql("original_id = #{id} AND #{eql_sql(:mission_id, replicator.target_mission_id)}").first
    else
      nil
    end
  end

  # Makes a copy of this obj in the database according to replication options and the given replicator.
  def make_copy(context)
    # The mappings variable will hold a set of 2-element arrays, or strings.
    # These values describe how the existing object should be copied to the new one.
    # If value is a string, copy it verbatim. Else the values are SQL expressions representing the col name and new value, respectively.

    # First add the cols to be copied verbatim.
    mappings = klass.attribs_to_replicate

    # But don't copy verbatim columns that need to stay unique.
    if klass.replicable_opts[:uniqueness]
      mappings.delete(klass.replicable_opts[:uniqueness][:field].to_s)
    end

    # Now add the non-trivial mappings.
    mappings += date_col_mappings(replicator, context)
    mappings += unique_col_mappings(replicator, context)
    mappings += standardizable_col_mappings(replicator, context)
    mappings += backward_assoc_col_mappings(replicator, context)

    if klass.has_ancestry?
      new_ancestry = get_copy_ancestry(context)
      mappings << ['ancestry', new_ancestry.nil? ? nil : "'#{new_ancestry}'"]
    else
      new_ancestry = nil
    end

    new_id = do_insert(mappings)

    self.class.new(klass: klass, id: new_id, ancestry: new_ancestry, replicator: replicator)
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
      get_target_class_from_type_col = options[:target_klass].column_names.include?('type')

      cols = [:id]
      cols << :ancestry if options[:target_klass].has_ancestry?
      cols << :type if get_target_class_from_type_col
      data = db.select_all("SELECT #{cols.join(',')} FROM #{options[:target_klass].table_name} WHERE #{condition} #{options[:order]}")

      data.map do |attribs|
        tc = get_target_class_from_type_col ? attribs.delete('type').constantize : options[:target_klass]
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
        joined = [context[:copy_parent].ancestry, context[:copy_parent].id].compact.join('/')
        joined.blank? ? nil : joined
      end
    end

    def date_col_mappings(replicator, context)
      [['created_at', 'NOW()'], ['updated_at', 'NOW()']]
    end

    def unique_col_mappings(replicator, context)
      return [] unless uniq_spec = klass.replicable_opts[:uniqueness]
      generator = Replication::UniqueFieldGenerator.new(
        uniq_spec.merge(klass: klass, orig_id: id, mission_id: replicator.target_mission_id))
      [[uniq_spec[:field], ActiveRecord::Base.connection.quote(generator.generate)]]
    end

    def standardizable_col_mappings(replicator, context)
      mappings = []
      case replicator.mode
      when :promote
        mappings << ['is_standard', 1] if klass.standardizable?
      when :clone
        mappings << 'mission_id'
        mappings << 'is_standard' if klass.standardizable?
      when :to_mission
        mappings << ['mission_id', replicator.target_mission_id]
        mappings << ['standard_copy', 1] if klass.standardizable? && replicator.source_is_standard?
      end
      mappings << ['original_id', 'id'] if klass.standardizable?
      mappings
    end

    def backward_assoc_col_mappings(replicator, context)
      klass.backward_assocs.map do |assoc|
        begin
          if assoc.serialized?
            [assoc.foreign_key, serialized_backward_assoc_ids(assoc)]
          else
            [assoc.foreign_key, singular_backward_assoc_id(assoc)]
          end
        rescue Replication::BackwardAssocError
          # If we have explicit instructions to delete the object if an association is missing, make a note of it.
          $!.ok_to_skip = assoc.skip_obj_if_missing
          raise $! # Then we send on up the chain.
        end
      end
    end

    def singular_backward_assoc_id(assoc)
      orig_foreign_id = klass.where(id: id).pluck(assoc.foreign_key).first
      get_copy_id(assoc.target_class, orig_foreign_id) ||
        (raise Replication::BackwardAssocError.new("Couldn't find copy of #{assoc.target_class.name} ##{orig_foreign_id}"))
    end

    def serialized_backward_assoc_ids(assoc)
      orig_foreign_ids = klass.where(id: id).pluck(assoc.foreign_key).first
      return nil if orig_foreign_ids.nil?
      copy_ids = orig_foreign_ids.map do |orig_id|
        get_copy_id(assoc.target_class, orig_id) ||
          (raise Replication::BackwardAssocError.new("Couldn't find copy of #{assoc.target_class.name} ##{orig_id}"))
      end
      "'#{copy_ids.to_json}'"
    end

    def get_copy_id(target_class, orig_id)
      if target_class.standardizable?
        target_class.where(mission_id: replicator.target_mission_id, original_id: orig_id).pluck(:id).first
      elsif reuse_col = target_class.replicable_opts[:reuse_if_match]
        orig_reuse_val = target_class.where(id: orig_id).pluck(reuse_col).first
        target_class.where(mission_id: replicator.target_mission_id, reuse_col => orig_reuse_val).pluck(:id).first
      else
        replicator.history.get_copy(target_class, orig_id).try(:id)
      end
    end

    def do_insert(mappings)
      insert_cols = mappings.map{ |s| s.is_a?(Array) ? s[0] : s}.join(',')
      select_chunks = mappings.map{ |s| s.is_a?(Array) ? s[1] : s}.map{ |s| s.nil? ? 'NULL' : s }.join(',')
      db.insert("INSERT INTO #{klass.table_name} (#{insert_cols})
        SELECT #{select_chunks} FROM #{klass.table_name} WHERE id = #{id}")
    end
end
