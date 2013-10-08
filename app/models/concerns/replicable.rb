# methods that handle replicating changes to copies of core objects (forms, questions, etc.) within and across missions
module Replicable
  extend ActiveSupport::Concern

  JOIN_CLASSES = %w(Optioning Questioning Condition)

  included do
    # dsl-style method for setting options from base class
    def self.replicable(options = {})
      options[:assocs] = Array.wrap(options[:assocs])
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
      replication = Replication.new(:obj => self, :to_mission => to_mission_or_replication)
    end
    
    # wrap in transaction if this is the first call
    return replication.redo_in_transaction unless replication.in_transaction?

    # if we're on a recursive step AND we're doing a shallow copy AND this is not a join class, 
    # we don't need to do any recursive copying, so just return self
    if replication.recursed? && replication.shallow_copy? && !JOIN_CLASSES.include?(self.class.name)
      add_copy_to_parent(self, replication)
      return self
    end

    # if this is a standard object AND we're copying to a mission AND there exists a copy in the given mission,
    # then we don't need to create a new object
    if is_standard? && replication.has_to_mission? && (c = copy_for_mission(replication.to_mission))
      copy = c
    else
      # otherwise, we init the new object
      copy = self.class.new
    end

    # set the proper mission if applicable
    copy.mission_id = replication.to_mission.try(:id)

    # determine appropriate attribs to copy
    dont_copy = %w(id created_at updated_at mission_id mission is_standard standard_id standard) + replicable_opts(:dont_copy)

    # don't copy foreign key field of belongs_to associations
    replicable_opts(:assocs).each do |assoc|
      refl = self.class.reflect_on_association(assoc)
      dont_copy << refl.foreign_key if refl.macro == :belongs_to
    end

    # don't copy foreign key field of parent's has_* association, if applicable
    if replicable_opts(:parent)
      dont_copy << replicable_opts(:parent).to_s + '_id'
    end

    # copy attribs
    attribs_to_copy = attributes.except(*dont_copy)
    attribs_to_copy.each{|k,v| copy.send("#{k}=", v)}

    # if uniqueness property is set, make sure the specified field is unique
    if params = replicable_opts(:uniqueness)
      copy.send("#{params[:field]}=", self.ensure_unique_field(params.merge(:mission => replication.to_mission, :dest_obj => copy)))
    end

    # call a callback if requested
    if replicable_opts(:after_copy_attribs)
      self.send(replicable_opts(:after_copy_attribs), copy, replication.ancestors)
    end

    # add to parent before recursive step
    add_copy_to_parent(copy, replication)

    # if this is a standard obj, add to copies if not there already
    copies << copy if is_standard? && !copies.include?(copy)

    # replicate associations
    replicable_opts(:assocs).each do |assoc|
      if self.class.reflect_on_association(assoc).collection?
        # destroy any children in copy that don't exist in standard
        std_child_ids = send(assoc).map(&:id)
        copy.send(assoc).each do |o|
          unless std_child_ids.include?(o.standard_id)
            copy.changing_in_replication = true
            copy.send(assoc).destroy(o) 
          end
        end

        # RECURSIVE STEP: replicate the existing children
        send(assoc).each{|o| o.replicate(replication.clone_for_recursion(o, assoc, copy))}
      else

        # if orig assoc is nil, make sure copy is also
        if send(assoc).nil?
          if !copy.send(assoc).nil?
            copy.changing_in_replication = true
            copy.send(assoc).destroy
          end
        # else replicate
        else
          # RECURSIVE STEP: replicate the child
          send(assoc).replicate(replication.clone_for_recursion(send(assoc), assoc, copy))
        end
      end
    end

    # set flag so that standardizable callback doesn't call replicate again unnecessarily
    copy.changing_in_replication = true
    copy.save!

    return copy
  end

  def replicate_destruction(to_mission)
    if c = copy_for_mission(to_mission)
      c.destroy
    end
  end

  # adds the specified object to the parent object's association
  # we do it this way so that links between parent and children objects
  # are established during recursion instead of all at the end
  # this is because some child objects (e.g. conditions) need access to their parents
  def add_copy_to_parent(copy, replication)
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
  def ensure_unique_field(params)
    
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