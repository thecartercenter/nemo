class SmsTestsController < ApplicationController
  def new
    @sms_test = Sms::Test.new
  end
  
  # handles a request for a test. this will be an AJAX call so we only return the message body
  def create
    # create an sms object
    sms = Sms::Message.new(:direction => :incoming, :from => params[:sms_test][:from], :body => params[:sms_test][:body])
    
    # submit it to the handle method over in the SmsController and get the reply
    reply = SmsController.handle_sms(sms)
    
    # render the body of the reply
    render :text => reply.body
  end
end