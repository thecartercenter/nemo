# ELMO - Secure, robust, and versatile data collection.
# Copyright 2011 The Carter Center
#
# ELMO is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# ELMO is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with ELMO.  If not, see <http://www.gnu.org/licenses/>.
# 
class Broadcast < ActiveRecord::Base
  has_many(:broadcast_addressings)
  has_many(:recipients, :through => :broadcast_addressings, :source => :user)
  
  validates(:recipients, :presence => true)
  validates(:medium, :presence => true)
  validates(:subject, :presence => true, :if => Proc.new{|b| b.by_email?})
  validates(:which_phone, :presence => true, :if => Proc.new{|b| b.by_sms? || by_both?})
  validates(:body, :presence => true)
  validates(:body, :length => {:maximum => 140}, :if => Proc.new{|b| !b.by_email?})
  
  before_create(:deliver)
  
  default_scope(includes(:recipients).order("created_at DESC"))
    
  def self.medium_select_options
    [["SMS preferred (email if user has no phone)", "sms"],
     ["Email only", "email"],
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
  def by_sms?; medium == "sms"; end
  def by_email?; medium == "email"; end
  def by_both?; medium == "both"; end
  
  def deliver
    # sort recipients into email and sms
    smsees, emailees = sort_recipients
    # no sms recipients if email only
    smsees = [] if by_email?
    # everyone gets an email if email or both
    emailees = recipients unless by_sms?
    # send emails
    begin
      BroadcastMailer.broadcast(emailees, subject, body).deliver unless emailees.empty?
    rescue
      add_send_error("Email Error: #{$!}")
    end
    # send smses
    begin
      Smser.deliver(smsees, which_phone, "#{configatron.broadcast_tag} #{body}") unless smsees.empty?
    rescue
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
    recipients.each{|r| r.can_get_sms? ? sms << r : email << r}
    [sms, email]
  end
      
end
