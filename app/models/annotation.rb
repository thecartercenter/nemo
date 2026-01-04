# frozen_string_literal: true

# == Schema Information
#
# Table name: annotations
#
#  id         :uuid             not null, primary key
#  content    :text             not null
#  annotation_type :string(255) default("note"), not null
#  position_x :decimal(10, 2)
#  position_y :decimal(10, 2)
#  width      :decimal(10, 2)
#  height     :decimal(10, 2)
#  is_public  :boolean          default(TRUE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  author_id  :uuid             not null
#  response_id :uuid            not null
#  answer_id  :uuid
#
# Indexes
#
#  index_annotations_on_author_id    (author_id)
#  index_annotations_on_response_id  (response_id)
#  index_annotations_on_answer_id    (answer_id)
#  index_annotations_on_annotation_type (annotation_type)
#  index_annotations_on_is_public    (is_public)
#
# Foreign Keys
#
#  annotations_author_id_fkey    (author_id => users.id) ON DELETE => cascade
#  annotations_response_id_fkey  (response_id => responses.id) ON DELETE => cascade
#  annotations_answer_id_fkey    (answer_id => answers.id) ON DELETE => cascade
#

class Annotation < ApplicationRecord
  belongs_to :author, class_name: "User"
  belongs_to :response
  belongs_to :answer, optional: true

  validates :content, presence: true
  validates :annotation_type, presence: true

  scope :public_annotations, -> { where(is_public: true) }
  scope :by_type, ->(type) { where(annotation_type: type) }
  scope :recent, -> { order(created_at: :desc) }

  ANNOTATION_TYPES = %w[
    note
    highlight
    correction
    suggestion
    flag
    question
  ].freeze

  validates :annotation_type, inclusion: {in: ANNOTATION_TYPES}

  def can_be_edited_by?(user)
    author == user || user.admin? || user.role(response.mission) == "coordinator"
  end

  def can_be_deleted_by?(user)
    author == user || user.admin? || user.role(response.mission) == "coordinator"
  end

  def position
    {
      x: position_x,
      y: position_y,
      width: width,
      height: height
    }
  end

  def position=(pos)
    self.position_x = pos[:x]
    self.position_y = pos[:y]
    self.width = pos[:width]
    self.height = pos[:height]
  end
end
