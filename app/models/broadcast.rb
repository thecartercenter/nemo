require 'mission_based'
class Broadcast < ActiveRecord::Base
  include MissionBased

  has_many(:broadcast_addressings, :inverse_of => :broadcast)
  has_many(:recipients, :through => :broadcast_addressings, :source => :user)
  
  validates(:recipients, :presence => true)
  validates(:medium, :presence => true)
  validates(:subject, :presence => true, :if => Proc.new{|b| !b.sms_possible?})
  validates(:which_phone, :presence => true, :if => Proc.new{|b| b.sms_possible?})
  validates(:body, :presence => true)
  validates(:body, :length => {:maximum => 140}, :if => Proc.new{|b| b.sms_possible?})
  
  before_create(:deliver)
  
  default_scope(includes(:recipients).order("created_at DESC"))
    
  def self.medium_select_options
    [["SMS preferred (use email if a recipient has no phone)", "sms"],
     ["Email preferred (use SMS if a recipient has no email)", "email"],
     ["SMS only (don't send any emails)", "sms_only"],
     ["Email only (don't send any SMSes)", "email_only"],
     ["Both SMS and email", "both"]]
  end

  def self.which_phone_select_options
    [["Main phone only", "main_only"],
     ["Alternate phone only", "alternate_only"],
     ["Both phones", "both"]]
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
    # sort recipients into email and sms
    smsees, emailees = sort_recipients
    
    # send emails
    begin
      BroadcastMailer.broadcast(emailees, subject, body).deliver unless emailees.empty?
    rescue
      add_send_error("Email Error: #{$!}")
    end
    # send smses
    begin
      Smser.deliver(smsees, which_phone, "#{configatron.broadcast_tag} #{body}") unless smsees.empty?
    rescue Sms::Error
      # one error per line
      $!.to_s.split("\n").each{|e| add_send_error("SMS Error: #{e}")}
    end
    return true
  end
  
  def add_send_error(msg)
    self.send_errors = (send_errors.nil? ? "" : send_errors) + msg + "\n"
  end
  
  def sort_recipients
    sms = []
    email = []
    recipients.each do |r| 
      # send sms if recipient can get sms, medium is not email_only, and medium is not email (if r can get email)
      sms << r if r.can_get_sms? && medium != "email_only" && !(medium == "email" && r.can_get_email?)
      
      # same logic for email
      email << r if r.can_get_email? && medium != "sms_only" && !(medium == "sms" && r.can_get_sms?)
    end
    [sms, email]
  end
      
end
