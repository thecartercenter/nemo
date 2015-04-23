class Rack::Attack::Request
  def direct_auth?
    if path =~ %r{^/m/[a-z][a-z0-9]*/(.*)$}
      subpath = $1

      return true if subpath == 'formList.xml'
      return true if subpath =~ %r{^forms/([^/]+)\.xml$}
      return true if subpath =~ %r{^forms/([^/]+)/manifest\.xml$}
      return true if subpath =~ %r{^forms/([^/]+)/itemsets\.csv$}
      return true if subpath == 'submission.xml'
    end
  end
end

class Rack::Attack
  # Limit ODK Collect and other :direct_auth requests by IP address to 30 requests per minute
  throttle('req/ip', limit: 30, period: 1.minute) do |req|
    req.ip if req.direct_auth?
  end
end
