# methods that handle replicating changes to copies of core objects (forms, questions, etc.) within and across missions
module Replicable
  extend ActiveSupport::Concern

  JOIN_CLASSES = %w(Optioning Questioning Condition)

  # an initial list of attributes that we don't want to copy from the src_obj to the dest_obj
  ATTRIBS_NOT_TO_COPY = %w(id created_at updated_at mission_id mission is_standard standard_id standard)

  included do
    # dsl-style method for setting options from base class
    def self.replicable(options = {})
      options[:child_assocs] = Array.wrap(options[:child_assocs])
      options[:dont_copy] = Array.wrap(options[:dont_copy]).map(&:to_s)
      class_variable_set('@@replication_options', options)
    end

    # cleaner accessor for replication options
    def self.replication_options
      class_variable_defined?('@@replication_options') ? class_variable_get('@@replication_options') : nil
    end
  end

  # creates a duplicate in this or another mission
  def replicate(to_mission_or_replication = nil)

    # if mission or nil was passed in, we don't have a replication object, so we need to create one
    # a replication is an object to track replication parameters
    if to_mission_or_replication.is_a?(Replication)
      replication = to_mission_or_replication
    else
      replication = Replication.new(:src_obj => self, :to_mission => to_mission_or_replication)
    end
    
    # wrap in transaction if this is the first call
    return replication.redo_in_transaction unless replication.in_transaction?

    # if we're on a recursive step AND we're doing a shallow copy AND this is not a join class, 
    # we don't need to do any recursive copying, so just return self
    if replication.recursed? && replication.shallow_copy? && !JOIN_CLASSES.include?(self.class.name)
      add_replication_dest_obj_to_parents_assocation(self, replication)
      return self
    end

    # if we get this far we DO need to do recursive copying
    # get the obj to copy stuff to, and also tell the replication object about it
    dest_obj = replication_destination_obj(replication)
    replication.dest_obj = dest_obj

    # set the proper mission if applicable
    dest_obj.mission_id = replication.to_mission.try(:id)

    # copy attributes from src to parent
    attribs_to_copy_in_replication.each{|k,v| dest_obj.send("#{k}=", v)}

    # ensure uniqueness params are respected
    ensure_uniqueness_when_replicating(replication)

    # call a callback if requested
    if replicable_opts(:after_copy_attribs)
      self.send(replicable_opts(:after_copy_attribs), dest_obj, replication.ancestors)
    end

    # add to parent before recursive step
    add_replication_dest_obj_to_parents_assocation(dest_obj, replication)

    # if this is a standard obj, add the dest obj to the list of copies
    # unless it is there already
    copies << dest_obj if is_standard? && !copies.include?(dest_obj)

    # set flag so that standardizable callback doesn't call replicate again unnecessarily
    dest_obj.changing_in_replication = true

    # replicate associations
    replicate_child_associations(replication)

    dest_obj.save!

    return dest_obj
  end

  def replicate_destruction(to_mission)
    if c = copy_for_mission(to_mission)
      c.destroy
    end
  end

  # replicates all child associations
  def replicate_child_associations(replication)
    # loop over each assoc and call appropriate method
    replicable_opts(:child_assocs).each do |assoc|
      if self.class.reflect_on_association(assoc).collection?
        replicate_collection_association(assoc, replication)
      else
        replicate_non_collection_association(assoc, replication)
      end
    end
  end

  # replicates a collection-type association
  # by destroying any children on the dest obj that arent on the src obj
  # and then replicating the existing children of the src obj to the dest obj
  def replicate_collection_association(assoc_name, replication)
    # destroy any children in dest obj that don't exist source obj
    src_child_ids = send(assoc_name).map(&:id)
    replication.dest_obj.send(assoc_name).each do |o|
      unless src_child_ids.include?(o.standard_id)
        replication.dest_obj.send(assoc_name).destroy(o) 
      end
    end

    # replicate the existing children
    send(assoc_name).each{|o| replicate_child(o, assoc_name, replication)}
  end

  # replicates a non-collection-type association (e.g. belongs_to)
  def replicate_non_collection_association(assoc_name, replication)
    # if orig assoc is nil, make sure copy is also
    if send(assoc_name).nil?
      unless replication.dest_obj.send(assoc_name).nil?
        replication.dest_obj.send(assoc_name).destroy
        replication.dest_obj.send("assoc_name=", nil)
      end
    # else replicate the single child
    else
      replicate_child(send(assoc_name), assoc_name, replication)
    end
  end

  # calls replicate on an individual child object, generating a new set of replication params 
  # for this particular replicate call
  def replicate_child(child, assoc_name, replication)
    # build new replication param obj for child
    new_replication = replication.clone_for_recursion(child, assoc_name)

    # call replicate for the child object
    child.replicate(new_replication)
  end

  # gets the object to which the replication operation will copy attributes, etc.
  # may be a new object or an existing one depending on parameters
  def replication_destination_obj(replication)
    # if this is a standard object AND we're copying to a mission AND there exists a copy of this obj in the given mission,
    # then we don't need to create a new object, so return the existing copy
    if is_standard? && replication.has_to_mission? && (copy = copy_for_mission(replication.to_mission))
      return copy
    else
      # otherwise, we init and return the new object
      return self.class.new
    end
  end

  # gets a hash of attributes of this object that should be copied to the dest obj
  # in the current replication operation. this is surprisingly intricate
  def attribs_to_copy_in_replication
    # start with the initial, constant set
    dont_copy = ATTRIBS_NOT_TO_COPY

    # add the ones that are specified explicitly in the replicable options
    dont_copy += replicable_opts(:dont_copy)

    # don't copy foreign key field of belongs_to associations
    replicable_opts(:child_assocs).each do |assoc|
      refl = self.class.reflect_on_association(assoc)
      dont_copy << refl.foreign_key if refl.macro == :belongs_to
    end

    # don't copy foreign key field of parent's has_* association, if applicable
    if replicable_opts(:parent_assoc)
      dont_copy << replicable_opts(:parent_assoc).to_s + '_id'
    end

    # get hash and return
    attributes.except(*dont_copy)
  end

  # ensures the uniqueness replicable option is respected
  def ensure_uniqueness_when_replicating(replication)
    # if uniqueness property is set, make sure the specified field is unique
    if params = replicable_opts(:uniqueness)
      # setup the params for the call to the generate_unique_field_value method
      params = params.merge(:mission => replication.to_mission, :dest_obj => replication.dest_obj)

      # get a unique field value (e.g. name) for the dest_obj (may be the same as the source object's value)
      unique_field_val = generate_unique_field_value(params)

      # set the value on the dest_obj
      replication.dest_obj.send("#{params[:field]}=", unique_field_val)
    end
  end

  # adds the specified object to the applicable parent object's association
  # we do it this way so that links between parent and children objects
  # are established during recursion instead of all at the end
  # this is because some child objects (e.g. conditions) need access to their parents
  def add_replication_dest_obj_to_parents_assocation(copy, replication)
    # trivial case
    return unless replication.has_ancestors?

    # get immediate parent and reflect on association
    refl = replication.parent.class.reflect_on_association(replication.current_assoc)
    
    # associate object with parent using appropriate method depending on assoc type
    if refl.collection?
      # only copy if not already there
      unless replication.parent.send(replication.current_assoc).include?(copy)
        replication.parent.send(replication.current_assoc).send('<<', copy)
      end
    else
      replication.parent.send("#{replication.current_assoc}=", copy)
    end
  end

  # ensures the given name or other field would be unique, and generates a new name if it wouldnt be
  # (e.g. My Form 2, My Form 3, etc.) for the given name (e.g. My Form)
  # params[:mission] - the mission in which it should be unique
  # params[:dest_obj] - the object to which the name will be applied in the specified mission
  # params[:field] - the field to operate on
  # params[:style] - the style to adhere to in generating the unique value (:sep_words or :camel_case)
  def generate_unique_field_value(params)
    
    # extract any numeric suffix from existing value
    if params[:style] == :sep_words
      prefix = send(params[:field]).gsub(/( \d+)?$/, '')
    else
      prefix = send(params[:field]).gsub(/(\d+)?$/, '')
    end

    # keep track of whether we found the exact name
    found_exact = false

    # build a relation to get existing objs
    existing = self.class.for_mission(params[:mission])

    # if the dest_obj has an ID (is not a new record), 
    # be sure to exclude that when looking for conflicting objects
    existing = existing.where('id != ?', params[:dest_obj]) unless params[:dest_obj].new_record?

    # get the number suffixes of all existing objects
    # e.g. if there are My Form, Other Form, My Form 4, My Form 3, TheForm return [1, 4, 3]
    existing_nums = existing.map do |obj|

      # for the current match, check if it's an exact match and take note
      if obj.send(params[:field]).downcase.strip == send(params[:field]).downcase.strip
        found_exact = true 
      end

      # check if the current existing object's name matches the name we're looking for
      if params[:style] == :sep_words
        m = obj.send(params[:field]).match(/^#{prefix}\s*( (\d+))?\s*$/i)
      else
        m = obj.send(params[:field]).match(/^#{prefix}((\d+))?\s*$/i)
      end

      # if there was no match, return nil (this will be compacted out of the array at the end)
      if m.nil?
        nil
      
      # else if we got a match then we must examine what matched
      # if it was just the prefix, the number is 1
      elsif $2.nil?
        1
      
      # otherwise we matched a digit so use that
      else
        $2.to_i
      end
    end.compact

    # if we didn't find the exact match or any prefix matches, then no need to add any new suffix
    # just return the name as is
    return send(params[:field]) if existing_nums.empty? || !found_exact

    # copy num is max of existing plus 1
    copy_num = existing_nums.max + 1
    
    # suffix string depends on style
    if params[:style] == :sep_words
      suffix = " #{copy_num}"
    else
      suffix = copy_num.to_s
    end
    
    # now build the new value and return
    "#{prefix}#{suffix}"
  end

  # convenience method for replication options
  def replicable_opts(key)
    self.class.replication_options[key]
  end

end