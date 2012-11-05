class BroadcastAddressing < ActiveRecord::Base
  belongs_to(:broadcast, :inverse_of => :broadcast_addressings)
  belongs_to(:user, :inverse_of => :broadcast_addressings)
end
