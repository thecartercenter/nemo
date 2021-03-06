# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: broadcasts
#
#  id                  :uuid             not null, primary key
#  body                :text             not null
#  medium              :string(255)      not null
#  recipient_selection :string(255)      not null
#  send_errors         :text
#  sent_at             :datetime
#  source              :string(255)      default("manual"), not null
#  subject             :string(255)
#  which_phone         :string(255)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  mission_id          :uuid             not null
#
# Indexes
#
#  index_broadcasts_on_mission_id  (mission_id)
#
# Foreign Keys
#
#  broadcasts_mission_id_fkey  (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

class Broadcast < ApplicationRecord
  include MissionBased

  def self.receivable_association
    {name: :broadcast_addressings, fk: :addressee}
  end
  include Receivable

  validates :medium, presence: true
  validates :recipient_selection, presence: true
  validates :subject, presence: true, unless: :sms_possible?
  validates :which_phone, presence: true, if: :sms_possible?
  validates :body, presence: true
  validates :body, length: {maximum: 140}, if: :sms_possible?
  validate :validate_recipients

  # options for the medium used for the broadcast
  MEDIUM_OPTIONS = %w[sms email sms_only email_only both].freeze

  MEDIUM_OPTIONS_WITHOUT_SMS = %w[email_only].freeze

  # options for which phone numbers the broadcast should be sent to
  WHICH_PHONE_OPTIONS = %w[main_only alternate_only both].freeze

  # options for recipients
  RECIPIENT_SELECTION_OPTIONS = %w[all_users all_enumerators specific].freeze

  scope :manual_only, -> { where(source: "manual") }

  def self.terminate_sub_relationships(broadcast_ids)
    BroadcastAddressing.where(broadcast_id: broadcast_ids).delete_all
    Sms::Message.where(broadcast_id: broadcast_ids).delete_all
  end

  def sms_possible?
    medium != "email_only"
  end

  def email_possible?
    medium != "sms_only"
  end

  def specific_recipients?
    recipient_selection == "specific"
  end

  # Delivers broadcast and catches any errors.
  # Re-raises the first error raised (if any) so the job can handle it.
  # Both Email and SMS?
  def deliver
    errors = []
    errors << deilver_emails_and_return_any_errors
    errors << deilver_smses_and_return_any_errors
    errors.compact!
    raise errors.first if errors.any?
  end

  def recipient_numbers
    @recipient_numbers ||= [].tap do |numbers|
      actual_recipients.each do |r|
        next unless r.can_get_sms?
        numbers << r.phone if main_phone?
        numbers << r.phone2 if alternate_phone?
      end
    end.compact
  end

  # Returns total number of users getting an sms.
  def sms_recipient_count
    return 0 unless sms_possible?
    @sms_recipient_count ||= actual_recipients.count(&:can_get_sms?)
  end

  # Returns a set of hashes of form {user: x, phone: y} for recipients that got smses.
  # If sms was sent to both phones, returns primary only.
  # options[:max] - The max number to return (defaults to all).
  def sms_recipient_hashes(options = {})
    return [] unless sms_possible?
    @sms_recipient_hashes ||= [].tap do |hashes|
      actual_recipients.each do |r|
        next unless r.can_get_sms?
        hashes << {user: r, phone: main_phone? ? r.phone : r.phone2}
        break if options[:max] && hashes.size >= options[:max]
      end
    end
  end

  def recipient_emails
    @recipient_emails ||= actual_recipients.map { |r| r.email if r.can_get_email? }.compact
  end

  private

  def deilver_emails_and_return_any_errors
    return unless email_possible? && recipient_emails.present?
    BroadcastMailer.broadcast(to: recipient_emails, subject: subject, body: body, mission: mission)
      .deliver_now
    nil
  rescue StandardError => e
    add_send_error(I18n.t("broadcast.email_error") + ": #{e}")
    save
    e
  end

  def deilver_smses_and_return_any_errors
    return unless sms_possible? && recipient_numbers.present?
    Sms::Broadcaster.new(mission: mission).deliver(self)
    nil
  rescue Sms::Error => e
    # one error per line
    e.to_s.split("\n").each { |line| add_send_error(I18n.t("broadcast.sms_error") + ": #{line}") }
    save
    e
  end

  def add_send_error(msg)
    self.send_errors = (send_errors || +"") << (send_errors.blank? ? "" : "\n") << msg
  end

  # Returns the recipients of the message. If recipient_selection is set to all_users or all_enumerators,
  # this will be different than `recipients`.
  def actual_recipients
    @actual_recipients ||=
      case recipient_selection
      when "specific"
        (recipient_users + recipient_groups.flat_map(&:users)).uniq
      when "all_users"
        mission.users
      when "all_enumerators"
        mission.users.where("assignments.role" => "enumerator")
      when "", nil
        []
      else
        raise "invalid recipient_selection"
      end
  end

  def validate_recipients
    # If no recipients at all, show 'can't be blank' error
    if specific_recipients? && recipients.empty?
      errors.add(:recipient_ids, :blank)

    # Else ensure at least one of the selected recipients can get the message!
    elsif !(sms_possible? && recipient_numbers.present?) && !(email_possible? && recipient_emails.present?)
      attrib_to_add_error = specific_recipients? ? :recipient_ids : :recipient_selection
      errors.add(attrib_to_add_error, :no_recipients)
    end
  end

  def main_phone?
    %w[main_only both].include?(which_phone)
  end

  def alternate_phone?
    %w[alternate_only both].include?(which_phone)
  end
end
