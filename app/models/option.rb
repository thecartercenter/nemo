class Option < ActiveRecord::Base
  include MissionBased, FormVersionable, Translatable
  
  has_many(:option_sets, :through => :option_settings)
  has_many(:option_settings, :inverse_of => :option, :dependent => :destroy, :autosave => true)
  has_many(:answers, :inverse_of => :option)
  has_many(:choices, :inverse_of => :option)
  
  validate(:integrity)
  validate(:name_lengths)
  
  before_destroy(:check_assoc)
  after_destroy(:notify_form_versioning_policy_of_destroy)
  after_save(:invalidate_cache)
  after_destroy(:invalidate_cache)
  
  default_scope(includes(:option_sets => [:questionings, {:questions => {:questionings => :form}}]))
  
  translates :name, :hint
  
  # the max number of suggestion matches to return
  MAX_SUGGESTIONS = 5

  # returns an array of hashes representing suggested options matching the given mission and textual query
  def self.suggestions(mission, query)
    # fetch all mission options from the cache
    options = Rails.cache.fetch("mission_options/#{mission.id}", :expires_in => 2.minutes) do
      Option.unscoped.includes(:option_sets).for_mission(mission).all
    end

    # scan for options matching query
    matches = []; exact_match = false
    for i in 0...options.size
      # if we have a a partial match
      if options[i].name && options[i].name =~ /#{query}/i
        # if also an exact match, set a flag and put it at the top
        if options[i].name =~ /^#{query}$/i
          matches.insert(0, options[i])
          exact_match = true
        # otherwise just insert at the end
        else
          matches << options[i]
        end
      end
    end
    
    # trim results to max size (couldn't do this earlier b/c had to search whole list for exact match)
    matches = matches[0...MAX_SUGGESTIONS]
    
    # convert to hashes for json
    hashes = matches.map{|o| o.as_json}
    
    # if there was no exact match, we append a 'new option' placeholder
    unless exact_match
      hashes << Option.new(:name => query).as_json
    end
    
    hashes
  end
  
  def published?; !option_sets.detect{|os| os.published?}.nil?; end
  
  def questions; option_sets.collect{|os| os.questions}.flatten.uniq; end
  
  # returns all forms on which this option appears
  def forms
    option_sets.collect{|os| os.questionings.collect(&:form)}.flatten.uniq
  end
  
  def as_json(options = {})
    { 
      :id => id,
      :name => name,
      :locales => available_locales.sort,
      :set_names => option_sets.map{|os| os.name}.join(', ')
    }
  end

  private
    def integrity
      # error if anything has changed (except names/hints) and the option is published
      errors.add(:base, :cant_change_if_published) if published? && (changed? && !changed.reject{|f| f =~ /^_?(name|hint)/}.empty?)
    end

    def check_assoc
      # could be in a published form but no responses yet
      raise DeletionError.new(:cant_delete_if_published) if published?
    end
    
    # checks that all name fields have lengths at most 30 chars
    def name_lengths
      errors.add(:base, :names_too_long) if name_translations && name_translations.detect{|l,t| !t.nil? && t.size > 30}
    end
    
    # invalidate the mission option cache after save, destroy
    def invalidate_cache
      Rails.cache.delete("mission_options/#{mission_id}")
    end
end
