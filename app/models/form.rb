require 'mission_based'
class Form < ActiveRecord::Base
  include MissionBased

  has_many(:questions, :through => :questionings)
  has_many(:questionings, :order => "rank", :autosave => true, :dependent => :destroy, :inverse_of => :form)
  has_many(:responses, :inverse_of => :form)
  belongs_to(:type, :class_name => "FormType", :foreign_key => :form_type_id, :inverse_of => :forms)
  
  validates(:name, :presence => true, :length => {:maximum => 32})
  validates(:type, :presence => true)
  validate(:cant_change_published)
  validate(:name_unique_per_mission)
  
  validates_associated(:questionings)
  
  before_create(:init_downloads)
  before_destroy(:check_assoc)
  
  # no pagination
  self.per_page = 1000000
  
  scope(:with_form_type, order("form_types.name, forms.name").includes(:type))
  scope(:published, where(:published => true))
  scope(:with_questions, includes(:type, {:questionings => [:form, :condition, {:question => 
    [:type, :translations, {:option_set => {:options => :translations}}]}]}).order("questionings.rank"))
    
  # finds the highest 'version' number of all forms with the given base name
  # returns nil if no forms found
  def self.max_version(base_name)
    mv = all.collect{|f| m = f.name.match(/^#{base_name}( v(\d+))?$/); m ? (m[2] ? m[2].to_i : 1) : 0}.max
    mv == 0 ? nil : mv
  end
  
  def as_json(options = {})
    {:id => id, :name => name, :full_name => full_name}
  end
  
  def temp_response_id
    "#{name}_#{ActiveSupport::SecureRandom.random_number(899999999) + 100000000}"
  end
  
  def version
    "1.0" # this isn't implemented yet
  end
  
  def full_name
    "#{type.name}: #{name}"
  end
  
  def option_sets
    questions.collect{|q| q.option_set}.compact.uniq
  end
  
  def visible_questionings
    questionings.reject{|q| q.hidden}
  end
  
  def max_rank
    questionings.map{|qing| qing.rank || 0}.max || 0
  end
  
  def update_ranks(new_ranks)
    # set but don't save the new orderings
    questionings.each_index do |i| 
      if new_ranks[questionings[i].id.to_s]
        questionings[i].rank = new_ranks[questionings[i].id.to_s].to_i
      end
    end
    
    # validate the condition orderings (raises an error if they're invalid)
    questionings.each{|qing| qing.verify_condition_ordering}
  end
  
  def destroy_questionings(qings)
    transaction do
      # delete the qings
      qings.each do |qing|
        questionings.delete(qing)
        qing.destroy
      end
      
      # fix the ranks
      questionings.each_with_index{|q, i| q.rank = i + 1}
      
      save
    end
  end
  
  def toggle_published
    self.published = !self.published?
    self.downloads = 0
    save
  end
  
  def add_download
    self.downloads += 1
    save
  end
  
  # makes a copy of the form, with a new name and a new set of questionings
  def duplicate
    # get the base name
    base = name.match(/^(.+?)( v(\d+))?$/)[1]
    version = (self.class.max_version(base) || 1) + 1
    # create the new form and set the basic attribs
    cloned = self.class.new(:mission_id => mission_id, :name => "#{base} v#{version}", :published => false, :form_type_id => form_type_id)
    # clone all the questionings
    cloned.questionings = Questioning.duplicate(questionings)
    # done!
    cloned.save
  end
  
  private
    def cant_change_published
      # if this is a published form and something other than published and downloads changes, wrong!
      if published_was && !(changed - %w[published downloads]).empty?
        errors.add(:base, "A published form can't be edited.") 
      end
    end
    def init_downloads
      self.downloads = 0
      return true
    end
    def check_assoc
      if published?
        raise "You can't delete form '#{name}' because it is published."
      elsif !responses.empty?
        raise "You can't delete form '#{name}' because it has associated responses."
      end
    end
    
    def name_unique_per_mission
      errors.add(:name, "must be unique") if self.class.for_mission(mission).where("name = ? AND id != ?", name, id).count > 0
    end
end
