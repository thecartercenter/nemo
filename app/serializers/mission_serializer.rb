# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: missions
#
#  id           :uuid             not null, primary key
#  compact_name :string(255)      not null
#  locked       :boolean          default(FALSE), not null
#  name         :string(255)      not null
#  shortcode    :string(255)      not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_missions_on_compact_name  (compact_name) UNIQUE
#  index_missions_on_shortcode     (shortcode) UNIQUE
#
# rubocop:enable Layout/LineLength

class MissionSerializer < ApplicationSerializer
  fields :id, :name
end
