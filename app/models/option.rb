class Option < ActiveRecord::Base
  include MissionBased, FormVersionable, Translatable
  
  has_many(:option_sets, :through => :option_settings)
  has_many(:option_settings, :inverse_of => :option, :dependent => :destroy, :autosave => true)
  has_many(:answers, :inverse_of => :option)
  has_many(:choices, :inverse_of => :option)
  
  validates(:value, :presence => true)
  validates(:value, :numericality => true, :if => Proc.new{|o| !o.value.blank?})
  validate(:integrity)
  validate(:name_lengths)
  
  before_destroy(:check_assoc)
  after_destroy(:notify_form_versioning_policy_of_destroy)
  
  default_scope(includes(:option_sets => [:questionings, {:questions => {:questionings => :form}}]))
  
  translates :name, :hint
  
  # creates a set of options with the given English names and mission
  def self.create_simple_set(names, mission)
    options = []
    names.each_with_index{|n, idx| options << create(:name_en => n, :mission => mission, :value => idx + 1)}
    options
  end
  
  def published?; !option_sets.detect{|os| os.published?}.nil?; end
  
  def questions; option_sets.collect{|os| os.questions}.flatten.uniq; end
  
  # returns all forms on which this option appears
  def forms
    option_sets.collect{|os| os.questionings.collect(&:form)}.flatten.uniq
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
      errors.add(:base, :names_too_long) if name_translations.detect{|l,t| !t.nil? && t.size > 30}
    end
end
