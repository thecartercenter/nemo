require 'test_helper'

class SmsDecoderTest < ActiveSupport::TestCase
  # submitting to unpublished form should produce appropriate error
  # submitting to non-existant form should produce appropriate error
  # submitting to outdated form should produce appropriate error
  # submitting to non-smsable form should produce appropriate error
  # submitting to form without permission should produce appropriate error
  # decoding should be case insensitive
  # form with single question should work
  # multiple messages should work
  # date types with separators should work
  # date types without separators should work
  # tiny text question should work
  # tiny text question followed by another question should work
  # integer question should work
  # decimal question should work
  # select_one question should work
  # select_multiple question should work

end