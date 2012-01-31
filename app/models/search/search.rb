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
class Search::Search < ActiveRecord::Base
  # finds or creates a search based on the given class_name and str
  def self.find_or_create(params)
    find_or_create_by_class_name_and_str(params[:class_name], params[:str])
  end

  # parses the search string
  def parse
    @parser = Search::Parser.new(self)
    @parser.parse
  end

  # applies this search to the given relation
  def apply(relation)
    parse unless @parser
    # apply the needed associations
    relation = relation.joins(Report::Join.list_to_sql(@parser.assoc))
    # apply the conditions
    relation.where(@parser.sql)
  end
  
  def examples
    klass.search_examples
  end
  
  def klass
    @klass ||= Kernel.const_get(class_name)
  end
end