# frozen_string_literal: true

class UserSession < Authlogic::Session::Base
  # only session related configuration goes here, see documentation for sub modules of Authlogic::Session
  # other config goes in acts_as block
  logout_on_timeout(true)
  allow_http_basic_auth(false) # We handle our own basic auth
  httponly(true)
  secure(Rails.env.production?)

  # override find() to eager load User.assignments
  def self.find(*args)
    with_scope(find_options: User.includes(:assignments)) do
      super
    end
  end

  def to_key
    new_record? ? nil : [send(self.class.primary_key)]
  end
end
