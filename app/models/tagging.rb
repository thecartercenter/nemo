# frozen_string_literal: true

# Tagging associates questions with tags
class Tagging < ApplicationRecord
  include Replication::Replicable

  acts_as_paranoid

  belongs_to :question
  belongs_to :tag

  delegate :mission_id, to: :question

  replicable child_assocs: :tag, backward_assocs: :question, dont_copy: %i[question_id tag_id]
end
