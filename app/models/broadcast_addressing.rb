class BroadcastAddressing < ActiveRecord::Base
  belongs_to(:broadcast)
  belongs_to(:user)
end
