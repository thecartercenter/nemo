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
class WelcomeController < ApplicationController
  def index
    # this page is not permission controlled since we don't want the "must login" error message to show up
    return redirect_to_login unless current_user

    @dont_print_title = true
    @user_count = User.count
    @observer_count = User.observers.count
    @pub_form_count = Form.published.count
    @unpub_form_count = Form.count - @pub_form_count
    @self_response_count = Response.by(current_user).count
    @total_response_count = Response.count
    @recent_responses_count = Response.recent_count
    @unreviewed_response_count = Response.unreviewed.count
    
    render(:partial => "blocks") if ajax_request?
  end
end
