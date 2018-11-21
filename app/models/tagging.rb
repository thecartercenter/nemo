class Tagging < ApplicationRecord
  include Replication::Replicable

  acts_as_paranoid

  belongs_to :question
  belongs_to :tag

  delegate :mission_id, to: :question

  replicable child_assocs: :tag, dont_copy: [:question_id, :tag_id]
end
