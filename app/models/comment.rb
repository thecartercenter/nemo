# frozen_string_literal: true

# == Schema Information
#
# Table name: comments
#
#  id         :uuid             not null, primary key
#  content    :text             not null
#  comment_type :string(255)    default("general"), not null
#  is_resolved :boolean         default(FALSE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  author_id  :uuid             not null
#  response_id :uuid            not null
#  parent_id  :uuid
#
# Indexes
#
#  index_comments_on_author_id    (author_id)
#  index_comments_on_response_id  (response_id)
#  index_comments_on_parent_id    (parent_id)
#  index_comments_on_comment_type (comment_type)
#  index_comments_on_is_resolved  (is_resolved)
#
# Foreign Keys
#
#  comments_author_id_fkey    (author_id => users.id) ON DELETE => cascade
#  comments_response_id_fkey  (response_id => responses.id) ON DELETE => cascade
#  comments_parent_id_fkey    (parent_id => comments.id) ON DELETE => cascade
#

class Comment < ApplicationRecord
  belongs_to :author, class_name: "User"
  belongs_to :response
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: "parent_id", dependent: :destroy
  has_many :mentions, dependent: :destroy
  has_many :mentioned_users, through: :mentions, source: :user

  validates :content, presence: true
  validates :comment_type, presence: true

  scope :top_level, -> { where(parent_id: nil) }
  scope :resolved, -> { where(is_resolved: true) }
  scope :unresolved, -> { where(is_resolved: false) }
  scope :by_type, ->(type) { where(comment_type: type) }
  scope :recent, -> { order(created_at: :desc) }

  COMMENT_TYPES = %w[
    general
    question
    suggestion
    issue
    approval
    rejection
    annotation
  ].freeze

  validates :comment_type, inclusion: {in: COMMENT_TYPES}

  after_create :extract_mentions
  after_create :notify_mentioned_users

  def resolve!
    update!(is_resolved: true)
  end

  def unresolve!
    update!(is_resolved: false)
  end

  def is_reply?
    parent_id.present?
  end

  def is_top_level?
    parent_id.nil?
  end

  def can_be_edited_by?(user)
    author == user || user.admin? || user.role(response.mission) == "coordinator"
  end

  def can_be_deleted_by?(user)
    author == user || user.admin? || user.role(response.mission) == "coordinator"
  end

  private

  def extract_mentions
    # Extract @username mentions from content
    mentioned_usernames = content.scan(/@(\w+)/).flatten

    mentioned_usernames.each do |username|
      user = User.find_by(login: username)
      mentions.create!(user: user) if user && user.missions.include?(response.mission)
    end
  end

  def notify_mentioned_users
    mentioned_users.each do |user|
      NotificationService.create_for_user(
        user,
        "comment_mention",
        "You were mentioned in a comment",
        message: "#{author.name} mentioned you in a comment on response #{response.shortcode}",
        data: {
          comment_id: id,
          response_id: response.id,
          author_name: author.name,
          content: content.truncate(100)
        },
        mission: response.mission
      )
    end
  end
end
