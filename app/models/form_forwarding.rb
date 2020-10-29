# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: form_forwardings
#
#  id             :uuid             not null, primary key
#  recipient_type :string(255)      not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  form_id        :uuid             not null
#  recipient_id   :uuid             not null
#
# Indexes
#
#  form_forwardings_full                   (form_id,recipient_id,recipient_type) UNIQUE
#  index_form_forwardings_on_form_id       (form_id)
#  index_form_forwardings_on_recipient_id  (recipient_id)
#
# Foreign Keys
#
#  form_forwardings_form_id_fkey  (form_id => forms.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

class FormForwarding < ApplicationRecord
  belongs_to :form
  belongs_to :recipient, polymorphic: true
end
