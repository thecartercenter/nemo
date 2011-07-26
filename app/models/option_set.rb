class OptionSet < ActiveRecord::Base
  has_many(:option_settings)
  has_many(:options, :through => :option_settings)
  
  def self.select_options
    all(:order => "name").collect{|os| [os.name, os.id]}
  end
end
