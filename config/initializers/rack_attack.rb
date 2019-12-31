# frozen_string_literal: true

class Rack::Attack::Request
  def direct_auth?
    # Match paths starting with "/m/mission_name", but exclude "/m/mission_name/sms" paths
    return Regexp.last_match(1) !~ /^sms/ if path =~ %r{^/m/[a-z][a-z0-9]*/(.*)$}
  end

  def login_related?
    path =~ %r{/user-session\b} || path =~ %r{/login\b} || path =~ %r{/confirm-login\b}
  end

  def login_attempts_exceeded?
    env["rack.attack.matched"] == "login-attempts/ip" && env["rack.attack.match_type"] == :track
  end
end

# Limit ODK Collect requests by IP address to N requests per minute
Rack::Attack.throttle("direct-auth-req/ip", limit: proc { configatron.direct_auth_request_limit },
                                            period: 1.minute) do |req|
  req.ip if req.direct_auth?
end

# Track rate of attempted logins by IP address per minute to allow reCAPTCHA display
# We use double the amount specified by login_captcha_threshold to account for
# the GET/POST cycle of a failed login attempt
Rack::Attack.track("login-attempts/ip", limit: proc { 2 * configatron.login_captcha_threshold },
                                        period: 1.minute) do |req|
  req.ip if req.login_related?
end

# Set 'elmo.captcha_required=true' in the Rack env if the rate is exceeded
ActiveSupport::Notifications.subscribe("rack.attack") do |_, _, _, _, req|
  if req.login_attempts_exceeded?
    Rails.logger.info("Login attempts per minute exceeded; enabling reCAPTCHA for #{req.ip}")
    req.env["elmo.captcha_required"] = true
  end
end
