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
    # default to current mission if not specified
    to_mission ||= mission if respond_to?(:mission)

    # determine whether deep or shallow, unless already set
    # by default, we do a deep copy iff we're copying to a different mission
    options[:deep_copy] = mission != to_mission if options[:deep_copy].nil?

    # copy's immediate parent is just copy_parents.last
    copy_parent = copy_parents.last

    # if we're on a recursive step AND we're doing a shallow copy AND this is not a join class, just return self
    if options[:recursed] && !options[:deep_copy] && !%w(Optioning Questioning Condition).include?(self.class.name)
      copy = self
      add_copy_to_parent(copy, copy_parents, parent_assoc)

    # if this is a standard object AND we're copying to a mission AND there exists in the mission an object already referencing this standard,
    # just return that object, no need to replicate further
    elsif is_standard? && !to_mission.nil? && respond_to?(:mission) && (instance = self.class.for_mission(to_mission).where(:standard_id => self.id).first)
      # TODO test replication of standard object that already exists
      copy = instance
      add_copy_to_parent(copy, copy_parents, parent_assoc)

    else

      # init the copy
      copy = self.class.new

      # set the recursed flag in the options so we will know what to do with deep copying
      options[:recursed] = true

      # puts "--------"
      # puts "class:" + self.class.name
      # puts "deep:" + options[:deep_copy].inspect
      # puts "recursing:" + options[:recursed].inspect
      # puts "copy parents:"
      # copy_parents.each{|p| puts p.inspect}

      # determine appropriate attribs to copy
      dont_copy = %w(id created_at updated_at mission_id is_standard standard_id) + self.class.replication_options[:dont_copy]

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
      attributes.except(*dont_copy).each{|k,v| copy.send("#{k}=", v)}

      # if property is set, change the name
      if params = self.class.replication_options[:uniqueness]
        copy.send("#{params[:field]}=", self.make_unique(params.merge(:mission => to_mission)))
      end

      # call a callback if requested
      if self.class.replication_options[:after_copy_attribs]
        self.send(self.class.replication_options[:after_copy_attribs], copy, copy_parents)
      end

      # add to parent before recursive step
      add_copy_to_parent(copy, copy_parents, parent_assoc)

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

      copy_parents.pop

      # set the proper mission if applicable
      copy.mission = to_mission if respond_to?(:mission)

      # if this is a standard obj, set the copy's standard to this
      copy.standard = self if is_standard?

      copy.save!
    end

    return copy
  end

  def add_copy_to_parent(copy, copy_parents, parent_assoc)
    return if copy_parents.empty?
    parent = copy_parents.last
    refl = parent.class.reflect_on_association(parent_assoc)
    if refl.collection?
      parent.send(parent_assoc).send('<<', copy)
    else
      parent.send("#{parent_assoc}=", copy)
    end
  end

  # gets the appropriate name or other field for a copy (e.g. My Form Copy, My Form Copy 2, etc.) for the given name (e.g. My Form)
  # params[:mission] - the mission in which it should be unique
  # params[:field] - the field to operate on
  # params[:style] - the style to adhere to in generating the unique value (:sep_words or :camel_case)
  def make_unique(params)
    copy_word = I18n.t("common.copy")
    
    # extract any copy suffix from existing value
    if params[:style] == :sep_words
      prefix = send(params[:field]).gsub(/ \(#{copy_word}( \d+)?\)$/, '')
    else
      prefix = send(params[:field]).gsub(/#{copy_word}(\d+)?$/, '')
    end

    # get all existing copy numbers
    existing_nums = self.class.for_mission(params[:mission]).map do |obj|
      if params[:style] == :sep_words
        m = obj.send(params[:field]).match(/^#{prefix}( \(#{copy_word}( (\d+))?\))?$/)
      else
        m = obj.send(params[:field]).match(/^#{prefix}(#{copy_word}((\d+))?)?$/)
      end

      # if there was no match, return nil
      if m.nil?
        nil
      
      # else if we got a match then we must examine what matched
      # if it was just the prefix, the number is 0
      elsif $1.nil?
        0
      
      # if there was no digit matched, it was just the word 'copy' so the number is 1
      elsif $3.nil?
        1
      
      # otherwise we matched a digit so use that
      else
        $3.to_i
      end
    end.compact

    # if there was no matches, then the copy num is 0 (we shouldn't append a copy suffix)
    copy_num = if existing_nums.empty?
       0
    # else copy num is max of existing plus 1
    else
      existing_nums.max + 1
    end
    
    # if copy num is 0, no suffix
    if copy_num == 0
      suffix = ''
    
    else
      # number string is empty string if 1, else the number plus space
      if params[:style] == :sep_words
        num_str = copy_num == 1 ? '' : " #{copy_num}"
        suffix = " (#{copy_word}#{num_str})"
      else
        num_str = copy_num == 1 ? '' : copy_num.to_s
        suffix = "#{copy_word}#{num_str}"
      end
    end
    
    # now build the new value
    "#{prefix}#{suffix}"
  end

end