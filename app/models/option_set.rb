class OptionSet < ActiveRecord::Base
  has_many(:option_settings)
  has_many(:options, :through => :option_settings)
end
