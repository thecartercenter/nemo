class Broadcast < ActiveRecord::Base
  has_many(:broadcast_addressings)
  has_many(:recipients, :through => :broadcast_addressings, :source => :user)
  
  validates(:recipients, :presence => true)
  validates(:medium, :presence => true)
  validates(:subject, :presence => true, :if => Proc.new{|b| b.by_email?})
  validates(:body, :presence => true)
  validates(:body, :length => {:maximum => 140}, :if => Proc.new{|b| !b.by_email?})
  
  before_create(:deliver)
  
  def self.sorted(params)
    params.merge!(:order => "created_at desc")
    paginate(:all, params)
  end
  
  def self.default_eager
    [:recipients]
  end
  
  def self.medium_select_options
    [["SMS preferred (email if no mobile phone)", "sms"],
     ["Email only", "email"],
     ["Both SMS and email", "both"]]
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
      BroadcastMailer.broadcast(emailees, subject, body).deliver
    rescue
      add_send_error("Email Error: #{$!}")
    end
    # send smses
    begin
      Smser.deliver(smsees, body)
    rescue
      # one error per line
      $!.to_s.split("\n").each{|e| add_send_error("SMS Error: #{e}")}
    end
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
