namespace :stress do
  desc "Load/Stress test the app"
  task :test, [:count,
               :loops,
               :sms_incoming_token,
               :mission_name,
               :login,
               :password,
               :domain,
               :port] do |t, args|

    require 'ruby-jmeter'

    args.with_defaults(count: 1,
                       loops: 1,
                       sms_incoming_token: '',
                       mission_name: '',
                       login: '',
                       password: '',
                       domain: 'loadtest1.getelmo.org',
                       port: 443)

    p args
    start_stress_test(*args.to_hash.values)
  end
end

def start_stress_test(count, loops, sms_incoming_token, mission_name, login, password, domain, port)
  jmeter_path = '/usr/local/apache-jmeter-2.13/bin/'

  test do
    defaults domain: domain, port: port.to_i, protocol: 'https'

    cookies clear_each_iteration: true

    extract name: 'authenticity_token',
            regex: 'input type="hidden" name="authenticity_token" value="(.+?)"'

    csv_data_set_config filename: 'messages_signature.csv',
       variableNames: 'message,phone_number,twilio_signature'

    threads count: count.to_i, loops: loops.to_i do
      think_time 1000, 1000

      transaction 'Send SMS messages' do
        header({name: 'X-Twilio-Stub-Signature', value: "${twilio_signature}"})

        submit name: 'sms-submit', url: "/m/#{mission_name}/sms/submit/#{sms_incoming_token}",
          always_encode: true,
          fill_in: {"From"=>"${phone_number}", "Body"=>"${message}"}
      end

      transaction 'Log in and navigate app' do

        visit name: 'login', url: '/en/login' do
          assert contains: 'Login', scope: 'main'
        end

        submit name: 'login-submit', url: '/en/user-session',
          always_encode: true,
          fill_in: {
            'utf8'                          => '✓',
            'authenticity_token'            => '${authenticity_token}',
            'user_session[login]'           => login,
            'user_session[password]'        => password,
            'commit'                        => 'Login',
          }

        visit name: 'responses', url: "/en/m/#{mission_name}/responses"
        visit name: 'reports', url: "/en/m/#{mission_name}/reports"
        visit name: 'forms', url: "/en/m/#{mission_name}/forms"
        visit name: 'questions', url: "/en/m/#{mission_name}/questions"
        visit name: 'option-sets', url: "/en/m/#{mission_name}/option-sets"
        visit name: 'users', url: "/en/m/#{mission_name}/users"
        visit name: 'broadcasts', url: "/en/m/#{mission_name}/broadcasts"
        visit name: 'sms', url: "/en/m/#{mission_name}/sms"
      end
    end

    view_results_tree
    graph_results
    aggregate_graph
    summary_report

  end.run(path: jmeter_path,
          properties: "#{jmeter_path}jmeter.properties",
          gui: true)

end
