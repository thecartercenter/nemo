# frozen_string_literal: true

module Sms
  # The approximate interval between requests is roughly
  # BRUTE_FORCE_CHECK_WINDOW / BRUTE_FORCE_LOCKOUT_THRESHOLD
  # but in the current implementation there is no technical minimum interval between requests.
  #
  # If the threshold is 3, then a user could submit 3 messages simultaneously,
  # they would just need to wait the duration of the BRUTE_FORCE_CHECK_WINDOW
  # before submitting any additional attempts after that.
  BRUTE_FORCE_CHECK_WINDOW = 1.minute
  BRUTE_FORCE_LOCKOUT_THRESHOLD = 3 # number of attempts within window before failure

  def self.table_name_prefix
    "sms_"
  end
end
