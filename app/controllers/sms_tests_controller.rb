class SmsTestsController < ApplicationController
  # authorization via CanCan
  load_and_authorize_resource :class => "Sms::Test"

  def new
  end

  # handles a request for a test. this will be an AJAX call so we only return the message body
  def create
    # create an incoming sms object
    sms = Sms::Incoming.create(:adapter_name => 'Test Console',
      :to => configatron.incoming_sms_number,
      :from => params[:sms_test][:from],
      :body => params[:sms_test][:body],
      :mission => current_mission)

    if reply = Sms::Handler.new.handle(sms)
      reply.adapter_name = 'Test Console'
      reply.save
    end

    # render the body of the reply
    render :text => reply ? reply.body : "<em>#{t('sms_console.no_reply')}</em>".html_safe
  end

  protected
    # specify the class the this controller controls, since it's not easily guessed
    def model_class
      Sms::Test
    end
end
