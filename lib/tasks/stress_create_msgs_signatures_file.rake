require 'task_helpers/stress_sms_helper'

namespace :stress do
  desc "Generate a csv file with msg,number and signature for JMeter test"
  task :create_msgs_signatures_file, [:auth_token,
                                      :incoming_token,
                                      :mission_name,
                                      :base_url,
                                      :number,
                                      :quantity] => [:environment] do |t, args|

    args.with_defaults(auth_token: '',
                       incoming_token: '',
                       mission_name: 'missionone',
                       base_url: 'http://localhost:8443',
                       number: '+553598765432',
                       quantity: 10)

    url = "#{args[:base_url]}/m/#{args[:mission_name]}/sms/submit/#{args[:incoming_token]}"

    open('messages_signature.csv', 'w') do |f|
      (1..args[:quantity].to_i).each do |i|
        message = StressSmsHelper.build_message_for_form('iad', false)
        signature = StressSmsHelper.signature_for_params(url,
          {"From"=>"#{args[:number]}", "Body"=>"#{message}"},
          args[:auth_token])

        f.puts "#{message},#{args[:number]},#{signature}"
      end
    end
  end
end
