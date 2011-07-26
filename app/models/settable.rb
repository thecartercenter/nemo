class Settable < ActiveRecord::Base
  has_one(:setting)
  
  def setting_or_default
    setting || Setting.create(:settable_id => id, :value => default)
  end
end
