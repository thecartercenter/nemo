class OptionSetting < ActiveRecord::Base
  belongs_to(:option)
  belongs_to(:option_set)
end
