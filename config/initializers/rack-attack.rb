class Rack::Attack::Request
  def direct_auth?
    # Match paths starting with "/m/mission_name", but exclude "/m/mission_name/sms" paths
    if path =~ %r{^/m/[a-z][a-z0-9]*/(.*)$}
      return $1 !~ /^sms/
    end
  end
end

class Rack::Attack
  # Limit ODK Collect requests by IP address to N requests per minute
  throttle('direct-auth-req/ip', limit: proc { configatron.direct_auth_request_limit }, period: 1.minute) do |req|
    req.ip if req.direct_auth?
  end
end
