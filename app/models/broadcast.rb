class Broadcast < ActiveRecord::Base
  include MissionBased

  has_many(:broadcast_addressings, :inverse_of => :broadcast, :dependent => :destroy)
  has_many(:recipients, :through => :broadcast_addressings, :source => :user)

  validates(:recipients, :presence => true)
  validates(:medium, :presence => true)
  validates(:subject, :presence => true, :if => Proc.new{|b| !b.sms_possible?})
  validates(:which_phone, :presence => true, :if => Proc.new{|b| b.sms_possible?})
  validates(:body, :presence => true)
  validates(:body, :length => {:maximum => 140}, :if => Proc.new{|b| b.sms_possible?})
  validate(:check_eligible_recipients)

  default_scope(includes(:recipients).order("created_at DESC"))

  # this method isn't used except for attaching errors
  attr_accessor :to

  # options for the medium used for the broadcast
  MEDIUM_OPTIONS = %w(sms email sms_only email_only both)

  MEDIUM_OPTIONS_WITHOUT_SMS = %w(email_only)

  # options for which phone numbers the broadcast should be sent to
  WHICH_PHONE_OPTIONS = %w(main_only alternate_only both)

  def self.terminate_sub_relationships(broadcast_ids)
    BroadcastAddressing.where(broadcast_id: broadcast_ids).delete_all
  end

  def recipient_ids
    recipients.collect{|r| r.id}.join(",")
  end

  def recipient_ids=(ids)
    self.recipients = ids.split(",").collect{|id| User.find_by_id(id)}.compact
  end

  def sms_possible?
    medium != "email_only"
  end

  def email_possible?
    medium != "sms_only"
  end

  def deliver
    # send emails
    begin
      if email_possible? && recipient_emails.present?
        BroadcastMailer.broadcast(recipient_emails, subject, body).deliver
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
      $!.to_s.split("\n").each{|e| add_send_error(I18n.t("broadcast.sms_error") + ": #{e}")}
    end

    save if send_errors
  end

  def add_send_error(msg)
    self.send_errors = (send_errors.nil? ? "" : send_errors) + msg + "\n"
  end

  def no_possible_recipients?
    recipients.all?{ |u| u.email.blank? && u.phone.blank? && u.phone2.blank? }
  end

  def recipient_numbers
    @recipient_numbers ||= [].tap do |numbers|
      recipients.each do |r|
        next unless r.can_get_sms?
        numbers << r.phone if main_phone?
        numbers << r.phone2 if alternate_phone?
      end
    end
  end

  # Returns total number of users getting an sms.
  def sms_recipient_count
    return 0 unless sms_possible?
    @sms_recipient_count ||= recipients.count(&:can_get_sms?)
  end

  # Returns a set of hashes of form {user: x, phone: y} for recipients that got smses.
  # If sms was sent to both phones, returns primary only.
  # options[:max] - The max number to return (defaults to all).
  def sms_recipient_hashes(options = {})
    return [] unless sms_possible?
    @sms_recipient_hashes ||= [].tap do |hashes|
      recipients.each do |r|
        next unless r.can_get_sms?
        hashes << { user: r, phone: main_phone? ? r.phone : r.phone2 }
        break if options[:max] && hashes.size >= options[:max]
      end
    end
  end

  def recipient_emails
    @recipient_emails ||= recipients.map { |r| r.email if r.can_get_email? }.compact
  end

  private

    def check_eligible_recipients
      unless (sms_possible? && recipient_numbers.present?) || (email_possible? && recipient_emails.present?)
        errors.add(:to, :no_recipients)
      end
    end

    def main_phone?
      %w(main_only both).include?(which_phone)
    end

    def alternate_phone?
      %w(alternate_only both).include?(which_phone)
    end

end
