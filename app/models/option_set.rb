class OptionSet < ActiveRecord::Base
  has_many(:option_settings)
  has_many(:options, :through => :option_settings)
  has_many(:questions)
  has_many(:questionings, :through => :questions)
  
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
end
