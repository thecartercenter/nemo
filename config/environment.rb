# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
CommandCenter::Application.initialize!

# Standard date-time format
Time::DATE_FORMATS[:std_datetime] = "%Y-%m-%d %H:%M"
Time::DATE_FORMATS[:std_date] = "%Y-%m-%d"
Time::DATE_FORMATS[:std_time] = "%H:%M"
Time::DATE_FORMATS[:filename_datetime] = "%Y-%m-%d-%H%M"
Time::DATE_FORMATS[:filename_date] = "%Y-%m-%d"
Time::DATE_FORMATS[:filename_time] = "%H%M"
Time::DATE_FORMATS[:db_datetime] = "%Y-%m-%d %T"
Time::DATE_FORMATS[:db_date] = "%Y-%m-%d"
Time::DATE_FORMATS[:db_time] = "%T"
Time::DATE_FORMATS[:javarosa_datetime] = "%Y%m%d%H%M"
Time::DATE_FORMATS[:javarosa_date] = "%Y%m%d"
Time::DATE_FORMATS[:javarosa_time] = "%H%M"
