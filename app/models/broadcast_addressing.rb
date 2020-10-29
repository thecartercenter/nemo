# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: broadcast_addressings
#
#  id             :uuid             not null, primary key
#  addressee_type :string(255)      not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  addressee_id   :uuid             not null
#  broadcast_id   :uuid             not null
#
# Indexes
#
#  index_broadcast_addressings_on_addressee_id  (addressee_id)
#  index_broadcast_addressings_on_broadcast_id  (broadcast_id)
#
# Foreign Keys
#
#  broadcast_addressings_broadcast_id_fkey  (broadcast_id => broadcasts.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

class BroadcastAddressing < ApplicationRecord
  belongs_to :broadcast, inverse_of: :broadcast_addressings
  belongs_to :addressee, polymorphic: true, inverse_of: :broadcast_addressings
end
