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
class Subindex
  attr_accessor(:page, :extras)
  attr_reader(:stamp)
  
  # finds/creates a subindex for the given class name, and then sets the page number
  def self.find_and_update(session, user, class_name, page, action = "index")
    si = find_or_create(session, user, class_name, action)
    si.page = page if page
    si
  end
  
  # finds or creates a subindex for the given class_name
  def self.find_or_create(session, user, class_name, action = "index")
    session[:subindexes] ||= {}
    key = "#{class_name.underscore.to_sym}__#{action}"
    unless session[:subindexes][key] 
      si = new(class_name, user)
      session[:subindexes][key] = si
    end
    return session[:subindexes][key]
  end
  
  def self.clear_all(session)
    session.delete(:subindexes)
  end
  
  def initialize(class_name, user)
    @class_name, @extras, @user, @page = class_name, {}, user, 1
    @stamp = Time.now.to_i.to_s[-6,6]
    reset_search
  end
  
  def load
    r = klass
    r = Permission.restrict(r, :user => @user, :controller => @class_name.pluralize.underscore, :action => "index")
    r = @search.apply(r) if @search
    r.paginate(:page => @page)
  end
  
  def search
    reset_search if @search.nil?
    @search
  end
  
  def search=(s)
    # if this is a new Search object, reset the page number
    @page = 1 if @search != s
    # save the new Search
    @search = s
    # reset the search to an unsaved, blank Search if the given argument was nil
    reset_search if @search.nil?
  end
  
  def reset_search
    @search = Search::Search.new(:class_name => @class_name)
    @page = 1
  end
  
  def klass
    @klass ||= Kernel.const_get(@class_name)
  end
end