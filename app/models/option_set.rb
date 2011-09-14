class OptionSet < ActiveRecord::Base
  has_many(:option_settings, :dependent => :destroy)
  has_many(:options, :through => :option_settings, :include => :option, :order => "options.value desc")
  has_many(:questions)
  has_many(:questionings, :through => :questions)
  
  validates(:name, :presence => true, :uniqueness => true)
  validates_associated(:option_settings)
  validate(:at_least_one_option)
  validate(:unique_values)
  
  before_destroy(:check_assoc)
  
  def self.sorted(params = {})
    paginate(:all, params.merge(:order => "name"))
  end
  
  def self.per_page; 100; end

  def self.default_eager; [{:questionings => :form}, :questions, :options]; end
  
  def self.select_options
    all(:order => "name").collect{|os| [os.name, os.id]}
  end
  
  def published?
    # check for any published questionings
    !questionings.detect{|qing| qing.published?}.nil?
  end
  
  # finds or initializes an option_setting for every option in the database (never meant to be saved)
  def all_option_settings
    # make sure there is an associated answer object for each questioning in the form
    Option.all.collect{|o| option_setting_for(o) || option_settings.new(:option_id => o.id, :included => false)}
  end
  
  def all_option_settings=(params)
    # create a bunch of temp objects, discarding any unchecked options
    submitted = params.values.collect{|p| p[:included] == '1' ? OptionSetting.new(p) : nil}.compact
    
    # copy new choices into old objects, creating or deleting if necessary
    option_settings.match(submitted, Proc.new{|os| os.option_id}) do |orig, subd|
      # if both exist, do nothing
      # if submitted is nil, destroy the original
      if subd.nil?
        option_settings.delete(orig)
      # if original is nil, add the new one to this option_set's array
      elsif orig.nil?
        option_settings << subd
      end
    end
  end
    
  def option_setting_for(option)
    # get the matching option_setting
    option_setting_hash[option]
  end

  def option_setting_hash(options = {})
    @option_setting_hash = nil if options[:rebuild]
    @option_setting_hash ||= Hash[*option_settings.collect{|os| [os.option, os]}.flatten]
  end
  
  private
    def at_least_one_option
      errors.add(:base, "You must choose at least one option.") if option_settings.empty?
    end
    def check_assoc
      unless questions.empty?
        raise "You can't delete option set '#{name}' because one or more questions are associated with it."
      end
    end
    def unique_values
      values = option_settings.map{|o| o.option.value}
      Rails.logger.info(values)
      if values.uniq.size != values.size
        errors.add(:base, "Two or more of the options you've chosen have the same numeric value.")
      end
    end
end
