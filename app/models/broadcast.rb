class Broadcast < ActiveRecord::Base
  include MissionBased

  # This has_many through association stores specific users that were selected as recipients.
  # It will be empty if recipient_selection is all_users or all_observers.
  has_many :broadcast_addressings, inverse_of: :broadcast, dependent: :destroy
  has_many :recipients, through: :broadcast_addressings, as: :addressees, source: :addressee, source_type: "User"

  validates :medium, presence: true
  validates :recipient_selection, presence: true
  validates :recipient_ids, presence: true, if: :specific_recipients?
  validates :subject, presence: true, unless: :sms_possible?
  validates :which_phone, presence: true, if: :sms_possible?
  validates :body, presence: true
  validates :body, length: {maximum: 140}, if: :sms_possible?
  validate :check_eligible_recipients

  default_scope { includes(:recipients).order("broadcasts.created_at DESC") }

  # options for the medium used for the broadcast
  MEDIUM_OPTIONS = %w(sms email sms_only email_only both)

  MEDIUM_OPTIONS_WITHOUT_SMS = %w(email_only)

  # options for which phone numbers the broadcast should be sent to
  WHICH_PHONE_OPTIONS = %w(main_only alternate_only both)

  # options for recipients
  RECIPIENT_SELECTION_OPTIONS = %w(all_users all_observers specific_users)

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

  def recipient_names
    recipients.map(&:name).join(", ")
  end

  def specific_recipients?
    recipient_selection == "specific_users"
  end

  def deliver
    # send emails
    begin
      if email_possible? && recipient_emails.present?
        BroadcastMailer.broadcast(recipient_emails, subject, body).deliver_now
      end
    rescue
      add_send_error(I18n.t("broadcast.email_error") + ": #{$!}")
    end

    # send smses
    begin
      if sms_possible? && recipient_numbers.present?
        Sms::Broadcaster.deliver(self, which_phone, "#{configatron.broadcast_tag} #{body}")
      end
    rescue Sms::Error
      # one error per line
      $!.to_s.split("\n").each { |e| add_send_error(I18n.t("broadcast.sms_error") + ": #{e}") }
    end

    save if send_errors
  end

  def add_send_error(msg)
    self.send_errors = (send_errors.nil? ? "" : send_errors) + msg + "\n"
  end

  def recipient_numbers
    @recipient_numbers ||= [].tap do |numbers|
      actual_recipients.each do |r|
        next unless r.can_get_sms?
        numbers << r.phone if main_phone?
        numbers << r.phone2 if alternate_phone?
      end
    end
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
        hashes << { user: r, phone: main_phone? ? r.phone : r.phone2 }
        break if options[:max] && hashes.size >= options[:max]
      end
    end
  end

  def recipient_emails
    @recipient_emails ||= actual_recipients.map { |r| r.email if r.can_get_email? }.compact
  end

  private

  # Returns the recipients of the message. If recipient_selection is set to all_users or all_observers,
  # this will be different than `recipients`.
  def actual_recipients
    case recipient_selection
    when "specific_users"
      recipients
    when "all_users"
      mission.users
    when "all_observers"
      mission.users.where("assignments.role" => "observer")
    else
      raise "invalid recipient_selection"
    end
  end

  def check_eligible_recipients
    # No need to proceed if no recipients at all.
    return if specific_recipients? && recipients.empty?

    unless (sms_possible? && recipient_numbers.present?) || (email_possible? && recipient_emails.present?)
      attrib_to_add_error = specific_recipients? ? :recipient_ids : :recipient_selection
      errors.add(attrib_to_add_error, :no_recipients)
    end
  end

  def main_phone?
    %w(main_only both).include?(which_phone)
  end

  def alternate_phone?
    %w(alternate_only both).include?(which_phone)
  end
end
