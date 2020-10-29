# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: whitelistings
#
#  id                 :uuid             not null, primary key
#  whitelistable_type :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :uuid
#  whitelistable_id   :uuid
#
# Indexes
#
#  index_whitelistings_on_user_id           (user_id)
#  index_whitelistings_on_whitelistable_id  (whitelistable_id)
#
# Foreign Keys
#
#  whitelistings_user_id_fkey  (user_id => users.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

class Whitelisting < ApplicationRecord
  belongs_to :whitelistable, polymorphic: true
  belongs_to :user
end
