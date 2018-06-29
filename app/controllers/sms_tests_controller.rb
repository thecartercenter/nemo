class SmsTestsController < ApplicationController
  # authorization via CanCan
  load_and_authorize_resource class: "Sms::Test"

  def new
  end

  # Handles a request for a test. This will be an AJAX call so we only return the reply and forward body.
  def create
    # Create an incoming sms object.
    # Should eventually refactor to do this via the TestConsoleAdapter.
    incoming_msg = Sms::Incoming.create(adapter_name: Sms::Adapters::TestConsoleAdapter.service_name,
      to: nil,
      from: params[:sms_test][:from],
      body: params[:sms_test][:body],
      mission: current_mission
    )

    processor = Sms::Processor.new(incoming_msg)
    processor.process
    processor.finalize

    # Send both the reply and forward (if exist) via the TestConsoleAdapter.
    # This really just saves them and sets the adapter name.
    adapter = Sms::Adapters::Factory.instance.create("TestConsole")
    adapter.deliver(processor.reply) if processor.reply
    adapter.deliver(processor.forward) if processor.forward

    # Render the body of the reply.
    render plain: processor.reply.try(:body) || content_tag(:em, t('sms_console.no_reply'))
  end

  protected

  # specify the class the this controller controls, since it's not easily guessed
  def model_class
    Sms::Test
  end
end
