# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: media_objects
#
#  id         :uuid             not null, primary key
#  type       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  answer_id  :uuid
#
# Indexes
#
#  index_media_objects_on_answer_id  (answer_id)
#
# Foreign Keys
#
#  media_objects_answer_id_fkey  (answer_id => answers.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

require "rails_helper"

describe Media::Audio do
  include_context "media helpers"
  include_examples "accepts file types", %w[audio]
  include_examples "rejects file types", %w[image video]
end
