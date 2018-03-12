# frozen_string_literal: true

module Sms
  # Lightweight singleton duck type object used to model the system as a sender or reciever of SMS.
  class SiteUser
    include Singleton

    def name
      Settings.site_name
    end
  end
end
