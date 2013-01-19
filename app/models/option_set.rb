require 'mission_based'
class OptionSet < ActiveRecord::Base
  include MissionBased

  has_many(:option_settings, :dependent => :destroy, :autosave => true, :inverse_of => :option_set)
  has_many(:options, :through => :option_settings)
  has_many(:questions, :inverse_of => :option_set)
  has_many(:questionings, :through => :questions)
  
  validates(:name, :presence => true)
  validates(:ordering, :presence => true)
  validates_associated(:option_settings)
  validate(:at_least_one_option)
  validate(:unique_values)
  validate(:name_unique_per_mission)
  
  before_destroy(:check_assoc)
  
  default_scope(order("name"))
  scope(:for_index, includes(:questions, :options, {:questionings => :form}))
  
  self.per_page = 100

  # creates a simple yes/no/na option set
  def self.create_default(mission)
    options = Option.create_simple_set(%w(Yes No N/A), mission)
    set = OptionSet.new(:name => "Yes/No/NA", :ordering => "value_asc", :mission => mission)
    options.each{|o| set.option_settings.build(:option_id => o.id)}
    set.save!
  end

  def self.orderings
    [{:code => "value_asc", :name => "Value Low to High", :sql => "value asc"},
     {:code => "value_desc", :name => "Value High to Low", :sql => "value desc"}]
  end
  
  def self.ordering_select_options
    orderings.collect{|o| [o[:name], o[:code]]}
  end
  
  def sorted_options
    @sorted_options ||= options.sort{|a,b| (a.value.to_i <=> b.value.to_i) * (ordering && ordering.match(/desc/) ? -1 : 1)}
  end
  
  def published?
    # check for any published questionings
    !questionings.detect{|qing| qing.published?}.nil?
  end
  
  # finds or initializes an option_setting for every option in the database for current mission (never meant to be saved)
  def all_option_settings(options)
    # make sure there is an associated answer object for each questioning in the form
    options.collect{|o| option_setting_for(o) || option_settings.new(:option_id => o.id, :included => false)}
  end
  
  def all_option_settings=(params)
    # create a bunch of temp objects, discarding any unchecked options
    submitted = params.values.collect{|p| p[:included] == '1' ? OptionSetting.new(p) : nil}.compact
    
    # copy new choices into old objects, creating or deleting if necessary
    option_settings.compare_by_element(submitted, Proc.new{|os| os.option_id}) do |orig, subd|
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
  
  def as_json(options = {})
    Hash[*%w(id name ordering).collect{|k| [k, self.send(k)]}.flatten]
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
      if values.uniq.size != values.size
        errors.add(:base, "Two or more of the options you've chosen have the same numeric value.")
      end
    end
    def name_unique_per_mission
      errors.add(:name, "must be unique") if self.class.for_mission(mission).where("name = ? AND id != ?", name, id).count > 0
    end
end
