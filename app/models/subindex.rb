# Elmo - Secure, robust, and versatile data collection.
# Copyright 2011 The Carter Center
#
# Elmo is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Elmo is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Elmo.  If not, see <http://www.gnu.org/licenses/>.
# 
class Subindex
  attr_accessor(:page, :custom_conditions, :extras)
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
    @class_name = class_name
    @custom_conditions = []
    @extras = {}
    @user = user
    @page = 1
    @stamp = Time.now.to_i.to_s[-6,6]
    reset_search
  end
  
  def params
    cond = []
    # get any permission conditions
    cond << Permission.select_conditions(:user => @user, :controller => @class_name.pluralize.underscore, :action => "index")
    # get search conditions
    cond << (@search ? ((sc = @search.conditions).blank? ? "1" : sc) : "1")
    # add custom conditions set by user
    cond += custom_conditions
    # get eager associations
    eager = klass.default_eager + (@search ? @search.eager : [])
    # build and return params
    {:page => @page, :conditions => cond.collect{|c| "(#{c})"}.join(" and "), :include => eager}
  end
  
  def search
    reset_search if @search.nil?
    @search
  end
  
  def search=(s)
    if @search != s
      @page = 1
      @search = s
    end
    reset_search if @search.nil?
  end
  
  def reset_search
    @search = Search.find_or_create(:class_name => @class_name)
  end
  
  def klass
    @klass ||= Kernel.const_get(@class_name)
  end
end