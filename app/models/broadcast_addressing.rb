class BroadcastAddressing < ApplicationRecord
  belongs_to :broadcast, inverse_of: :broadcast_addressings
  belongs_to :addressee, polymorphic: true, inverse_of: :broadcast_addressings
end
