class Form < ActiveRecord::Base
  include MissionBased, Standardizable, Replicable

  has_many(:questions, :through => :questionings, :order => "questionings.rank")
  has_many(:questionings, :order => "rank", :autosave => true, :dependent => :destroy, :inverse_of => :form)
  has_many(:responses, :inverse_of => :form)
  
  has_many(:versions, :class_name => "FormVersion", :inverse_of => :form, :dependent => :destroy)
  
  # while a form has many versions, this is a reference to the most up-to-date one
  belongs_to(:current_version, :class_name => "FormVersion")
  
  validates(:name, :presence => true, :length => {:maximum => 32})
  validate(:cant_change_published)
  validate(:name_unique_per_mission)
  
  validates_associated(:questionings)
  
  before_create(:init_downloads)
  before_destroy(:check_assoc)
  
  # no pagination
  self.per_page = 1000000
  
  scope(:published, where(:published => true))
  scope(:with_questionings, includes(
    :questionings => [
      :form, 
      {:question => {:option_set => :options}},
      {:condition => [:option, :ref_qing]}
    ]
  ).order("questionings.rank"))
    
  replicable :assocs => :questionings, :uniqueness => {:field => :name, :style => :sep_words}, 
    :dont_copy => [:published, :downloads, :responses_count, :questionings_count, :upgrade_needed, :smsable, :current_version_id]

  def temp_response_id
    "#{name}_#{ActiveSupport::SecureRandom.random_number(899999999) + 100000000}"
  end
  
  def version
    "1.0" # this isn't implemented yet
  end
  
  def full_name
    # this used to include the form type, but for now it's just name
    name
  end
  
  def option_sets
    # going through the questionings model as that's the one that is eager-loaded in .with_questionings
    questionings.map(&:question).map(&:option_set).compact.uniq
  end
  
  def visible_questionings
    questionings.reject{|q| q.hidden}
  end
  
  # returns questionings that work with sms forms and are not hidden
  def smsable_questionings
    questionings.reject{|q| q.hidden || !q.question.qtype.smsable?}
  end
  
  def max_rank
    questionings.map{|qing| qing.rank || 0}.max || 0
  end
  
  # takes a hash of the form {"questioning_id" => "new_rank", ...}
  def update_ranks(new_ranks)
    # set but don't save the new orderings
    questionings.each_index do |i| 
      if new_ranks[questionings[i].id.to_s]
        questionings[i].rank = new_ranks[questionings[i].id.to_s].to_i
      end
    end
    
    # validate the condition orderings (raises an error if they're invalid)
    questionings.each{|qing| qing.condition_verify_ordering}
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
  
  # publishes the form and resets the download count
  # upgrades the version if necessary
  def publish!
    self.published = true
    self.downloads = 0
    
    # upgrade if necessary
    if upgrade_needed? || current_version.nil?
      upgrade_version!
    else
      save(:validate => false)
    end
  end
  
  # unpublishes this form
  def unpublish!
    self.published = false
    save(:validate => false)
  end
  
  # increments the download counter
  def add_download
    self.downloads += 1
    save(:validate => false)
  end
  
  # upgrades the version of the form and saves it
  def upgrade_version!
    if current_version
      self.current_version = current_version.upgrade
    else
      self.build_current_version(:form_id => id)
    end
    
    # since we've upgraded, we can lower the upgrade flag
    self.upgrade_needed = false
    
    save(:validate => false)
  end
  
  # sets the upgrade flag so that the form will be upgraded when next published
  def flag_for_upgrade!
    self.upgrade_needed = true
    save(:validate => false)
  end
  
  # checks if this form doesn't have any non-required questions
  # if options[:smsable] is set, specifically looks for non-required questions that are smsable
  def all_required?(options = {})
    @all_required ||= visible_questionings.reject{|qing| qing.required? || (options[:smsable] ? !qing.question.smsable? : false)}.empty?
  end
  
  private
    def cant_change_published
      # if this is a published form and something other than published and downloads changes, wrong!
      if published_was && !(changed - %w[published downloads]).empty?
        errors.add(:base, :cant_edit_published) 
      end
    end
    
    def init_downloads
      self.downloads = 0
      return true
    end
    
    def check_assoc
      if published?
        raise DeletionError.new(:cant_delete_published)
      elsif !responses.empty?
        raise DeletionError.new(:cant_delete_if_has_responses)
      end
    end
    
    def name_unique_per_mission
      errors.add(:name, :must_be_unique) unless unique_in_mission?(:name)
    end
end
