require 'task_helpers/stress_sms_helper'

namespace :stress do
  desc "Loads incoming and outgoing SMSs on db with their respective form responses"
  task :load_sms_messages_in_db, [:quantity, :mission_id, :words_file] => [:environment] do |t, args|
    args.with_defaults(quantity: 1,
      mission_id: 1,
      words_file: 'lib/task_helpers/1k_random_words.txt')

    p args

    StressSmsHelper.read_words_file args[:words_file]

    (1..args[:quantity].to_i).each do
      message_body = StressSmsHelper.build_message_for_form('iad', true)
      mission = Mission.find(args[:mission_id])
      incoming_params = { to: '', from: '+553598765432', body: message_body, mission: mission }

      incoming = StressSmsHelper.create_incoming_sms(incoming_params)
      reply = Sms::Handler.new.handle(incoming)
      StressSmsHelper.create_reply_sms(reply)
    end
  end
end
