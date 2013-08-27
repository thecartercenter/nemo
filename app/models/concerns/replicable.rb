module Replicable
  extend ActiveSupport::Concern

  included do
    cattr_accessor :replicable_assocs, :change_name_on_replicate, :non_replicable_attribs
  end

  # creates a duplicate in this or another mission
  def replicate(to_mission = nil, options = {})
    # default to current mission if not specified
    to_mission ||= mission if respond_to?(:mission)

    # determine whether deep or shallow, unless already set
    # by default, we do a deep copy iff we're copying to a different mission
    options[:deep_copy] = mission != to_mission if options[:deep_copy].nil?

    # puts self.class.name
    # puts "deep:" + options[:deep_copy].inspect
    # puts "recursing:" + options[:recursed].inspect

    # if we're on a recursive step AND we're doing a shallow copy AND this is not a join class, just return self
    return self if options[:recursed] && !options[:deep_copy] && !%w(Optioning Questioning).include?(self.class.name)

    # if this is a standard object AND we're copying to a mission AND there exists in the mission an object already referencing this standard,
    # just return that object, no need to replicate further
    if is_standard? && !to_mission.nil? && respond_to?(:mission) && (instance = self.class.for_mission(to_mission).where(:standard_id => self.id).first)
      return instance
    end

    # copy the appropriate attribs
    dont_copy = %w(id created_at updated_at mission_id is_standard standard_id)
    copy = self.class.new
    attributes.except(*dont_copy).each{|k,v| copy.send("#{k}=", v)}

    # if property is set, change the name
    copy.name = self.name_of_copy(to_mission) if self.class.change_name_on_replicate

    # set the recursed flag in the options so we will know what to do with deep copying
    options[:recursed] = true

    # replicate associations
    replicable_assocs.try(:each) do |assoc|
      if assoc[1] == :many
        copy.send("#{assoc[0]}=", send(assoc[0]).map{|o| o.replicate(to_mission, options)})
      else
        copy.send("#{assoc[0]}=", send(assoc[0]).replicate(to_mission, options))
      end
    end

    # set the proper mission if applicable
    copy.mission = to_mission if respond_to?(:mission)

    # if this is a standard obj, set the copy's standard to this
    copy.standard = self if is_standard?

    # save and return
    copy.save!
    copy
  end

  # gets the appropriate name for a copy (e.g. My Form Copy, My Form Copy 2, etc.) for the given name (e.g. My Form)
  def name_of_copy(to_mission)
    copy_word = I18n.t("common.copy")
    
    # extract any copy suffix from existing name
    prefix = name.gsub(/ \(#{copy_word}( \d+)?\)$/, '')
    
    # get all existing copy numbers
    existing_nums = self.class.for_mission(to_mission).map do |f|
      m = f.name.match(/^#{prefix}( \(#{copy_word}( (\d+))?\))?$/)
      
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
      num_str = copy_num == 1 ? '' : " #{copy_num}"
      suffix = " (#{copy_word}#{num_str})"
    end
    
    # now build the new name
    "#{prefix}#{suffix}"
  end

end