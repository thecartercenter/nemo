namespace :stress do
  desc "Stress test SMSes reception"
  task :sms_messages, [:count,
                       :loops,
                       :sms_incoming_token,
                       :mission_name,
                       :domain,
                       :port] do |t, args|

    require 'ruby-jmeter'

    args.with_defaults(count: 1,
                       loops: 1,
                       sms_incoming_token: '',
                       mission_name: '',
                       domain: 'loadtest1.getelmo.org',
                       port: 443)

    p args
    send_sms(*args.to_hash.values)
  end
end

def send_sms(count, loops, sms_incoming_token, mission_name, domain, port)
  jmeter_path = '../apache-jmeter-2.13/bin/'

  test do
    defaults domain: domain, port: port.to_i, protocol: 'https'

    cookies clear_each_iteration: true

    csv_data_set_config filename: 'messages_signature.csv',
       variableNames: 'message,phone_number,twilio_signature'

    threads count: count.to_i, loops: loops.to_i, scheduler: false do
      think_time 100, 50

      transaction 'Send SMS messages' do
        header({name: 'X-Twilio-Stub-Signature', value: "${twilio_signature}"})

        submit name: 'sms-submit', url: "/m/#{mission_name}/sms/submit/#{sms_incoming_token}",
          always_encode: true,
          fill_in: {"From"=>"${phone_number}", "Body"=>"${message}"}
      end
    end

  end.run(path: jmeter_path,
          properties: "#{jmeter_path}jmeter.properties")
end
