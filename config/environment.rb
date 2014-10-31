# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
ELMO::Application.initialize!

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
Time::DATE_FORMATS[:cache_datetime] = "%Y%m%d%H%M%S"


# ignore Tableau temp tables when dumping schema
ActiveRecord::SchemaDumper.ignore_tables = [/^#Tableau/]

# don't put obj name in json dumps
ActiveRecord::Base.include_root_in_json = false