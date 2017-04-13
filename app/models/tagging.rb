class Tagging < ApplicationRecord
  include MissionBased

  belongs_to :question
  belongs_to :tag

  delegate :mission_id, to: :question
end
