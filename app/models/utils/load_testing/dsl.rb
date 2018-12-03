# frozen_string_literal: true

module Utils
  module LoadTesting
    # Extends the JMeter DSL with helper methods
    class Dsl < RubyJmeter::ExtendedDSL
      def set_csrf_token
        visit("/en/login") do
          extract(name: "csrf-token", xpath: "//meta[@name='csrf-token']/@content", tolerant: true)
          extract(name: "csrf-param", xpath: "//meta[@name='csrf-param']/@content", tolerant: true)
        end

        http_header_manager(name: "X-CSRF-Token", value: "${csrf-token}")
      end

      def login(username, password)
        cookies(policy: "rfc2109", clear_each_iteration: false)

        transaction("login") do
          set_csrf_token
          submit_login(username, password)
        end
      end

      def basic_auth(username, password)
        auth = Base64.encode64("#{username}:#{password}")
        header([{name: "Authorization", value: "Basic #{auth}"}])
      end

      private

      def submit_login(username, password)
        submit("/en/user-session",
          fill_in: {
            "${csrf-param}" => "${__urlencode(${csrf-token})}",
            "user_session[login]" => username,
            "user_session[password]" => password
          })
      end
    end
  end
end
