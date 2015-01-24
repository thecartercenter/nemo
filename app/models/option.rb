class Option < ActiveRecord::Base
  include MissionBased, FormVersionable, Translatable, Replication::Replicable

  has_many(:option_sets, :through => :option_nodes)
  has_many(:option_nodes, :inverse_of => :option, :dependent => :destroy, :autosave => true)
  has_many(:answers, :inverse_of => :option)
  has_many(:choices, :inverse_of => :option)

  after_save(:invalidate_cache)
  after_destroy(:invalidate_cache)

  scope(:with_questions_and_forms, includes(:option_sets => [:questionings, {:questions => {:questionings => :form}}]))

  translates :name

  # We re-use options on replicate if they have the same canonical_name as the option being imported.
  # Options are not standardizable so we don't track the original_id (that would be overkill).
  replicable reuse_if_match: :canonical_name

  MAX_NAME_LENGTH = 45

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

  # Returns an Option in the given mission that has same canonical name as this Option.
  # Returns nil if not found.
  def similar_for_mission(other_mission)
    self.class.where(canonical_name: canonical_name, mission_id: other_mission.try(:id)).first
  end

  def as_json(options = {})
    if options[:for_option_set_form]
      super(:only => [:id, :name_translations], :methods => [:name, :set_names, :in_use?])
    else
      super(options)
    end
  end

  private

    # invalidate the mission option cache after save, destroy
    def invalidate_cache
      Rails.cache.delete("mission_options/#{mission_id}")
    end
end
