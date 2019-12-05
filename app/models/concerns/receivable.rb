# frozen_string_literal: true

# Methods relating to managing User and UserGroup recipients.
# Expects a receivable_association class method to be defined on the model before this module is included.
# The method should return a hash with :name and :fk as keys.
module Receivable
  extend ActiveSupport::Concern

  included do
    has_many receivable_association[:name],
      dependent: :destroy

    has_many :recipient_users,
      through: receivable_association[:name],
      as: receivable_association[:fk].to_s.pluralize,
      source: receivable_association[:fk],
      source_type: "User"

    has_many :recipient_groups,
      through: receivable_association[:name],
      as: receivable_association[:fk].to_s.pluralize,
      source: receivable_association[:fk],
      source_type: "UserGroup"
  end

  # Returns user and group recipients together, each wrapped in the Recipient wrapper.
  def recipients
    (recipient_users + recipient_groups).map { |r| Recipient.new(object: r) }
  end

  def recipients=(recipients)
    recipients.each do |r|
      case r.class.to_s
      when "User"
        recipient_users << r
      when "UserGroup"
        recipient_groups << r
      end
    end
  end

  def recipient_names
    recipients.map(&:name).join(", ")
  end

  def recipient_ids
    recipients.map(&:id)
  end

  def recipient_ids=(ids)
    user_ids = []
    group_ids = []
    ids.each do |str|
      type, _, id = str.rpartition("_")
      case type
      when "user" then user_ids << id
      when "user_group" then group_ids << id
      end
    end
    self.recipient_user_ids = user_ids
    self.recipient_group_ids = group_ids
  end

  def recipient_user_count
    recipient_count("User")
  end

  def recipient_group_count
    recipient_count("UserGroup")
  end

  # Gets count of recipients with given type without making any direct database calls.
  def recipient_count(type)
    send(self.class.receivable_association[:name]).select do |obj|
      obj["#{self.class.receivable_association[:fk]}_type"] == type
    end.size
  end
end
