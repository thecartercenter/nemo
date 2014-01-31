ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)

# methods for testing sms forms functionality
class ActiveSupport::TestCase

  # gets the version code for the current form
  def form_code
    @form.current_version.code
  end

end
