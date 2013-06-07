class SmsTestsController < ApplicationController
  def new
    @sms_test = Sms::Test.new
  end
  
  # handles a request for a test. this will be an AJAX call so we only return the message body
  def create
    # create an incoming sms object
    sms = Sms::Message.create(:from => params[:sms_test][:from], :body => params[:sms_test][:body], :mission => current_mission)
    
    # submit it to the handle method over in the SmsController and get the reply
    reply = SmsController.handle_sms(sms)
    
    # save the reply and let the sent_at default to now
    reply.save if reply
    
    # render the body of the reply
    render :text => reply ? reply.body : "<em>No reply.</em>".html_safe
  end
end