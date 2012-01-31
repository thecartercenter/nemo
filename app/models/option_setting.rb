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
class OptionSetting < ActiveRecord::Base
  belongs_to(:option)
  belongs_to(:option_set, :autosave => true)
  
  before_destroy(:no_answers_or_choices)
  
  # temp var used in the option_set form
  attr_writer :included
  
  def included
    # default to true
    defined?(@included) ? @included : true
  end
  
  # looks for answers and choices related to this option setting 
  def has_answers_or_choices?
    !option_set.questions.detect{|q| q.questionings.detect{|qing| qing.answers.detect{|a| a.option_id == option_id || a.choices.detect{|c| c.option_id == option_id}}}}.nil?
  end
  
  private
    def no_answers_or_choices
      if has_answers_or_choices?
        raise InvalidAssociationDeletionError.new(
          "You can't remove the option '#{option.name_eng}' because some responses are using it.")
      end
    end
end
