# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: answer_hierarchies
#
#  generations   :integer          not null
#  ancestor_id   :uuid             not null
#  descendant_id :uuid             not null
#
# Indexes
#
#  answer_desc_idx                                            (descendant_id)
#  index_answer_hierarchies_on_ancestor_id_and_descendant_id  (ancestor_id,descendant_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (ancestor_id => answers.id)
#  fk_rails_...  (descendant_id => answers.id)
#
# rubocop:enable Layout/LineLength

# Represents a hierarchical connection between two ResponseNodes.
# This class itself is only used to hold clone information.
class AnswerHierarchy < ApplicationRecord
  clone_options follow: []
end
