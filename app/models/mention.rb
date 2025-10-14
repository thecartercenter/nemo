# frozen_string_literal: true

# == Schema Information
#
# Table name: mentions
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  comment_id :uuid             not null
#  user_id    :uuid             not null
#
# Indexes
#
#  index_mentions_on_comment_id  (comment_id)
#  index_mentions_on_user_id     (user_id)
#  index_mentions_on_comment_id_and_user_id  (comment_id,user_id) UNIQUE
#
# Foreign Keys
#
#  mentions_comment_id_fkey  (comment_id => comments.id) ON DELETE => cascade
#  mentions_user_id_fkey     (user_id => users.id) ON DELETE => cascade
#

class Mention < ApplicationRecord
  belongs_to :comment
  belongs_to :user

  validates :comment_id, uniqueness: { scope: :user_id }
end