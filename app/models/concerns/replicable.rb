module Replicable
  extend ActiveSupport::Concern

  included do
    # dsl-style method for setting options from base class
    def self.replicable(options = {})
      options[:assocs] = Array.wrap(options[:assocs])
      options[:dont_copy] = Array.wrap(options[:dont_copy]).map(&:to_s)
      class_variable_set('@@replication_options', options)
    end

    # accessor for within the concern
    def self.replication_options
      class_variable_defined?('@@replication_options') ? class_variable_get('@@replication_options') : nil
    end
  end

  # creates a duplicate in this or another mission
  def replicate(to_mission = nil, options = {}, copy_parents = [], parent_assoc = nil)
    puts "---- replicating #{self.to_s} to #{to_mission.to_s}"

    # default to current mission if not specified
    to_mission ||= mission if respond_to?(:mission)

    # determine whether deep or shallow, unless already set
    # by default, we do a deep copy iff we're copying to a different mission
    options[:deep_copy] = mission != to_mission if options[:deep_copy].nil?

    # copy's immediate parent is just copy_parents.last
    copy_parent = copy_parents.last

    # if we're on a recursive step AND we're doing a shallow copy AND this is not a join class, just return self
    if options[:recursed] && !options[:deep_copy] && !%w(Optioning Questioning Condition).include?(self.class.name)
      add_copy_to_parent(self, copy_parents, parent_assoc)
      return self
    end

    # if this is a standard object AND we're copying to a mission AND there exists a copy in the given mission,
    # then we don't need to create a new object
    if is_standard? && !to_mission.nil? && (c = copy_for_mission(to_mission))
      puts 'found copy'
      copy = c
    else
      puts 'creating new'
      # init the copy
      copy = self.class.new
    end

    # set the recursed flag in the options so we will know what to do with deep copying
    options[:recursed] = true

    # puts "--------"
    # puts "class:" + self.class.name
    # puts "deep:" + options[:deep_copy].inspect
    # puts "recursing:" + options[:recursed].inspect
    # puts "copy parents:"
    # copy_parents.each{|p| puts p.inspect}

    # set the proper mission if applicable
    puts "setting mission for #{copy.class} to #{to_mission}"
    copy.mission_id = to_mission.try(:id)

    # determine appropriate attribs to copy
    dont_copy = %w(id created_at updated_at mission_id mission is_standard standard_id standard) + self.class.replication_options[:dont_copy]

    # don't copy foreign key field of belongs_to associations
    self.class.replication_options[:assocs].each do |assoc|
      refl = self.class.reflect_on_association(assoc)
      dont_copy << refl.foreign_key if refl.macro == :belongs_to
    end

    # don't copy foreign key field of parent's has_* association
    if parent_assoc
      refl = copy_parent.class.reflect_on_association(parent_assoc)
      if [:has_one, :has_many].include?(refl.macro)
        dont_copy << refl.foreign_key
      end
    end

    # copy attribs
    attribs_to_copy = attributes.except(*dont_copy)
    attribs_to_copy.each{|k,v| puts "copying #{k}"; copy.send("#{k}=", v)}

    # if uniqueness property is set, make sure the specified field is unique
    if params = self.class.replication_options[:uniqueness]
      copy.send("#{params[:field]}=", self.ensure_unique(params.merge(:mission => to_mission)))
    end

    # call a callback if requested
    if self.class.replication_options[:after_copy_attribs]
      self.send(self.class.replication_options[:after_copy_attribs], copy, copy_parents)
    end

    # add to parent before recursive step
    add_copy_to_parent(copy, copy_parents, parent_assoc)

    puts "copy before add to std copies array: " + copy.inspect

    # if this is a standard obj, add to copies if not there already
    copies << copy if is_standard? && !copies.include?(copy)

    puts "copy after add to std copies array: " + copy.inspect

    # add the new copy to the list of copy parents
    copy_parents = copy_parents + [copy]

    # replicate associations
    self.class.replication_options[:assocs].each do |assoc|
      if self.class.reflect_on_association(assoc).collection?
        send(assoc).each{|o| o.replicate(to_mission, options, copy_parents, assoc)}
      else
        send(assoc).replicate(to_mission, options, copy_parents, assoc) unless send(assoc).nil?
      end
    end

    copy.saving_in_replication = true
    copy.save!
    puts "copy after save: " + copy.inspect

    return copy
  end

  # adds the specified object to the parent object
  # we do it this way so that links between parent and children objects
  # are established during recursion instead of all at the end
  # this is because some child objects (e.g. conditions) need access to their parents
  def add_copy_to_parent(copy, copy_parents, parent_assoc)
    # trivial case
    return if copy_parents.empty?

    # get immediate parent and reflect on association
    parent = copy_parents.last
    refl = parent.class.reflect_on_association(parent_assoc)

    puts "adding #{copy.inspect} to parent"
    
    # associate object with parent using appropriate method depending on assoc type
    if refl.collection?
      puts "parent already has #{parent.send(parent_assoc).inspect}"
      if parent.send(parent_assoc).include?(copy)
        puts 'already there'
      else
        parent.send(parent_assoc).send('<<', copy)
      end
    else
      puts "setting on parent #{parent.id}"
      parent.send("#{parent_assoc}=", copy)
    end
  end

  # ensures the given name or other field would be unique, and generates a new name if it wouldnt be
  # (e.g. My Form 2, My Form 3, etc.) for the given name (e.g. My Form)
  # params[:mission] - the mission in which it should be unique
  # params[:field] - the field to operate on
  # params[:style] - the style to adhere to in generating the unique value (:sep_words or :camel_case)
  def ensure_unique(params)
    
    # extract any numeric suffix from existing value
    if params[:style] == :sep_words
      prefix = send(params[:field]).gsub(/( \d+)?$/, '')
    else
      prefix = send(params[:field]).gsub(/(\d+)?$/, '')
    end

    # keep track of whether we found the exact name
    found_exact = false

    # get all existing copy numbers
    existing_nums = self.class.for_mission(params[:mission]).map do |obj|
      found_exact = true if obj.send(params[:field]) == send(params[:field])

      if params[:style] == :sep_words
        m = obj.send(params[:field]).match(/^#{prefix}( (\d+))?$/)
      else
        m = obj.send(params[:field]).match(/^#{prefix}((\d+))?$/)
      end

      # if there was no match, return nil
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

    # if we didn't find the exact match or any prefix matches, then no need to add number
    return send(params[:field]) if existing_nums.empty? || !found_exact

    # copy num is max of existing plus 1
    copy_num = existing_nums.max + 1
    
    # number string is empty string if 1, else the number plus space
    if params[:style] == :sep_words
      suffix = " #{copy_num}"
    else
      suffix = copy_num.to_s
    end
    
    # now build the new value
    "#{prefix}#{suffix}"
  end

end