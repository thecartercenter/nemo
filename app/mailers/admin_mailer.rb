# ELMO - Secure, robust, and versatile data collection.
# Copyright 2011 The Carter Center
#
# ELMO is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# ELMO is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with ELMO.  If not, see <http://www.gnu.org/licenses/>.
# 
class AdminMailer < ActionMailer::Base
  default :from => configatron.site_email
  
  # mails an error report to the webmaster
  def error(exception, session = nil, params = nil, env = nil)
    @exception = exception
    @session = session
    @params = params
    @env = env
    path = env && env['REQUEST_URI'] && (": " + env['REQUEST_URI']) || ""
    mail(:to => configatron.webmaster_emails, :subject => "Error#{path}")
  end
end
