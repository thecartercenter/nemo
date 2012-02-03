# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
CommandCenter::Application.initialize!

# Standard date-time format
Time::DATE_FORMATS[:std_datetime] = "%Y-%m-%d %l:%M%p"