class Option < ActiveRecord::Base
  include MissionBased, FormVersionable, Translatable, Standardizable, Replicable

  has_many(:option_sets, :through => :optionings)
  has_many(:optionings, :inverse_of => :option, :dependent => :destroy, :autosave => true)
  has_many(:answers, :inverse_of => :option)
  has_many(:choices, :inverse_of => :option)
  has_many(:conditions, :inverse_of => :option)

  validate(:name_lengths)
  validate(:not_all_blank_name_translations)

  after_save(:invalidate_cache)
  after_destroy(:invalidate_cache)

  scope(:with_questions_and_forms, includes(:option_sets => [:questionings, {:questions => {:questionings => :form}}]))

  translates :name, :hint

  replicable :parent_assoc => :optioning, :user_modifiable => [:name_translations, :_name, :hint_translations, :_hint]

  # the max number of suggestion matches to return
  MAX_SUGGESTIONS = 5

  # returns an array of hashes representing suggested options matching the given mission and textual query
  def self.suggestions(mission, query)
    # fetch all mission options from the cache
    mission_id = mission ? mission.id : 'std'
    options = Rails.cache.fetch("mission_options/#{mission_id}", :expires_in => 2.minutes) do
      Option.unscoped.includes(:option_sets).for_mission(mission).all
    end

    # scan for options matching query
    matches = []; exact_match = false
    for i in 0...options.size
      # if we have a a partial match
      if options[i].name && options[i].name =~ /#{Regexp.escape(query)}/i
        # if also an exact match, set a flag and put it at the top
        if options[i].name =~ /^#{Regexp.escape(query)}$/i
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

    # if there was no exact match, we append a 'new option' placeholder
    unless exact_match
      matches << Option.new(:name => query)
    end

    matches
  end

  def published?; !option_sets.detect{|os| os.published?}.nil?; end

  def questions; option_sets.collect{|os| os.questions}.flatten.uniq; end

  def has_answers?
    !answers.empty?
  end

  def has_choices?
    !choices.empty?
  end

  # returns all forms on which this option appears
  def forms
    option_sets.collect{|os| os.questionings.collect(&:form)}.flatten.uniq
  end

  # returns whether this option is in use -- is referenced in any answers/choices AND/OR is published
  def in_use?
    published? || has_answers? || has_choices?
  end

  # gets the names of all option sets in which this option appears
  def set_names
    option_sets.map{|os| os.name}.join(', ')
  end

  def as_json(options = {})
    if options[:for_option_set_form]
      super(:only => [:id, :name_translations], :methods => [:name, :set_names, :in_use?])
    else
      super(options)
    end
  end

  private
    # checks that all name fields have lengths at most 30 chars
    def name_lengths
      errors.add(:base, :names_too_long) if name_translations && name_translations.detect{|l,t| !t.nil? && t.size > 30}
    end

    # invalidate the mission option cache after save, destroy
    def invalidate_cache
      Rails.cache.delete("mission_options/#{mission_id}")
    end

    # checks that at least one name translation is not blank
    def not_all_blank_name_translations
      errors.add(:base, :names_cant_be_all_blank) if name_translations.nil? || !name_translations.detect{|l,t| !t.blank?}
    end
end
