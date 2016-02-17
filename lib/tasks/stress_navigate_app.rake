namespace :stress do
  desc "Load/Stress test the app via simple user navigation"
  task :navigate_app, [:count, :loops, :mission_name, :login, :password,
    :domain, :port] do |t, args|

    require 'ruby-jmeter'

    args.with_defaults(count: 1, loops: 1, mission_name: '', login: '',
      password: '', domain: 'loadtest1.getelmo.org', port: 443)

    p args
    navigate(*args.to_hash.values)
  end
end

def navigate(count, loops, mission_name, login, password, domain, port)
  jmeter_path = '../apache-jmeter-2.13/bin/'

  test do
    defaults domain: domain, port: port.to_i, protocol: 'https'

    cookies clear_each_iteration: true

    extract name: 'authenticity_token',
            regex: 'input type="hidden" name="authenticity_token" value="(.+?)"'

    threads count: count.to_i, loops: loops.to_i, scheduler: false do
      think_time 500, 100

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

  end.run(path: jmeter_path,
          properties: "#{jmeter_path}jmeter.properties")
end
