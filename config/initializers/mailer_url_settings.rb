# This file MUST come lexically after local_config.rb.
ActionMailer::Base.default_url_options = configatron.url.to_h.slice(:host, :port, :protocol)
