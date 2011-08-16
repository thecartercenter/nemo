class Form < ActiveRecord::Base
  has_many(:questions, :through => :questionings)
  has_many(:questionings, :order => "rank", :autosave => true, :dependent => :destroy)
  has_many(:responses)
  belongs_to(:type, :class_name => "FormType", :foreign_key => :form_type_id)
  
  validates(:name, :presence => true, :uniqueness => true, :length => {:maximum => 32})
  validates(:type, :presence => true)
  validate(:cant_change_published)
  
  before_save(:fix_ranks)
  before_create(:init_downloads)
  before_destroy(:check_assoc)
  
  def self.per_page
    1000000
  end
  
  def self.sorted(params)
    params.merge!(:order => "form_types.name, forms.name")
    params[:page] ? paginate(:all, params) : find(:all, params)
  end
  
  def self.default_eager
    [:type]
  end
  
  def self.find_eager(id)
    find(id, :include => [:type, {:questionings => {:question => 
        [:type, :translations, {:option_set => {:option_settings => {:option => :translations}}}]
    }}])
  end
  
  def self.select_options(options = {})
    params = {:include => :type, :order => "form_types.name, forms.name"}
    params[:conditions] = {:is_published => options[:published]} if !options[:published].nil?
    all(params).collect{|f| [f.full_name, f.id]}
  end
  
  # finds the highest 'version' number of all forms with the given base name
  # returns nil if no forms found
  def self.max_version(base_name)
    mv = all.collect{|f| m = f.name.match(/^#{base_name}( v(\d+))?$/); m ? (m[2] ? m[2].to_i : 1) : 0}.max
    mv == 0 ? nil : mv
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
    questionings.map{|qing| qing.rank}.max || 0
  end
  
  def update_ranks(new_ranks)
    transaction{new_ranks.each_pair{|qing,rank| qing.update_rank(rank)}}
  end
  
  def destroy_questionings(qings)
    transaction do
      qings.each do |qing|
        questionings.delete(qing)
        qing.destroy
      end
      save
    end
  end
  
  def toggle_published
    self.is_published = !self.is_published?
    self.downloads = 0
    save
  end
  
  def add_download
    self.downloads += 1
    save
  end
  
  # makes a copy of the form, with a new name and a new set of questionings
  def clone
    # get the base name
    base = name.match(/^(.+?)( v(\d+))?$/)[1]
    version = (self.class.max_version(base) || 1) + 1
    # create the new form and set the basic attribs
    cloned = self.class.new(:name => "#{base} v#{version}", :is_published => false, :form_type_id => form_type_id)
    # clone all the questionings
    cloned.questionings = questionings.collect{|qing| qing.clone(cloned)}
    # done!
    cloned.save
  end
  
  private
    def cant_change_published
      # if this is a published form and something other than is_published and downloads changes, wrong!
      if is_published_was && !(changed - %w[is_published downloads]).empty?
        errors.add(:base, "A published form can't be edited.") 
      end
    end
    def fix_ranks
      questionings.each_index{|i| questionings[i].rank = i + 1}
      return true
    end
    def init_downloads
      self.downloads = 0
      return true
    end
    def check_assoc
      if is_published?
        raise "You can't delete form '#{name}' because it is published."
      elsif !responses.empty?
        raise "You can't delete form '#{name}' because it has associated responses."
      end
    end
end
