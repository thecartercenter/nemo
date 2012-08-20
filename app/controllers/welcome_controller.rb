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
    @pub_form_count = Form.published.count
    @unpub_form_count = Form.count - @pub_form_count
    restricted_responses = Permission.restrict(Response, :user => current_user, :controller => "responses", :action => "index")
    @self_response_count = restricted_responses.by(current_user).count
    @total_response_count = restricted_responses.count
    @recent_responses_count = Response.recent_count(restricted_responses)
    @unreviewed_response_count = restricted_responses.unreviewed.count
    
    render(:partial => "blocks") if ajax_request?
  end
end
