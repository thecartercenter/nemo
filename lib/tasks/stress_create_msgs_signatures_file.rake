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
        message = build_message_for_form('iad')
        signature = signature_for_params(url,
                                         {"From"=>"#{args[:number]}", "Body"=>"#{message}"},
                                         args[:auth_token])

        f.puts "#{message},#{args[:number]},#{signature}"
      end
    end
  end
end

def signature_for_params(url, params, auth_token)
  validator = Twilio::Util::RequestValidator.new auth_token
  validator.build_signature_for url, params
end

# This is for "Stress Test Form" on loadtest1
def build_message_for_form(form_code)
  responses = []
  responses << "1.#{random_letter('a','f')}"
  responses << "2.#{random_text}"
  responses << "3.#{random_letter('a','e')}"
  responses << "4.#{rand(1000000)}"
  responses << "5.#{random_text}"
  responses << "6.#{random_letter('a','h')}"
  responses << "7.#{random_letter('a','g')}"
  responses << "8.#{rand(1000000)}"
  responses << "9.#{random_letter('a','t')}"
  responses << "10.#{random_text}"

  "#{form_code} #{responses.join(' ')}"
end

def random_letter(from, to)
  [*from..to].sample
end

def random_text
  "#{random_letter('a','z')}text#{random_letter('a','z')}"
end
