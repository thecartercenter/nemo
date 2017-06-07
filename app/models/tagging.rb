class Tagging < ApplicationRecord
  include MissionBased

  acts_as_paranoid

  belongs_to :question
  belongs_to :tag

  delegate :mission_id, to: :question
end
