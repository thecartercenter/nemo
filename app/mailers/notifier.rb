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
class Notifier < ActionMailer::Base  
  default(:from => configatron.site_email)
  
  def password_reset_instructions(user) 
    @reset_url = edit_password_reset_url(user.perishable_token, :protocol => configatron.mailer_url_protocol)  
    mail(:to => user.email, :subject => "Password Reset Instructions")
  end
  
  def intro(user)
    @user = user
    @reset_url = edit_password_reset_url(user.perishable_token, :protocol => configatron.mailer_url_protocol)
    mail(:to => user.email, :subject => "Welcome to #{configatron.site_name}")
  end    
end