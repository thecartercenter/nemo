require 'translatable'

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
class Question < ActiveRecord::Base
  include Translatable
  
  belongs_to(:type, :class_name => "QuestionType", :foreign_key => :question_type_id)
  belongs_to(:option_set, :include => :options)
  has_many(:translations, :class_name => "Translation", :foreign_key => :obj_id, 
    :conditions => "translations.class_name='Question'", :autosave => true, :dependent => :destroy)
  has_many(:questionings, :dependent => :destroy, :autosave => true)
  has_many(:answers, :through => :questionings)
  has_many(:referring_conditions, :through => :questionings)
  has_many(:forms, :through => :questionings)

  validates(:code, :presence => true, :uniqueness => true)
  validates(:code, :format => {:with => /^[a-z][a-z0-9]{1,19}$/i}, :if => Proc.new{|q| !q.code.blank?})
  validates(:type, :presence => true)
  validates(:option_set_id, :presence => true, :if => Proc.new{|q| q.is_select?})
  validates(:english_name, :presence => true)
  validate(:integrity)
    
  before_destroy(:check_assoc)
  
  default_scope(order("code"))
  
  self.per_page = 100
  
  # returns questions that do NOT already appear in the given form
  def self.not_in_form(form)
    scoped.includes([:translations, :type]).
      where("(questions.id not in (select question_id from questionings where form_id='#{form.id}'))")
  end
  
  def self.select_options_by_code(questions = nil)
    questions ||= all
    questions.collect{|q| [q.code, q.id]}
  end
  
  def method_missing(*args)
    # enable methods like name_fra and hint_eng, etc.
    if args[0].to_s.match(/^(name|hint)_([a-z]{3})(_before_type_cast)?(=?)$/)
      send("#{$1}#{$4}", Language.by_code($2), *args[1..2])
    else
      super
    end
  end
  def respond_to?(symbol, *)
	is_translation_method?(symbol.to_s) || super
  end
  def respond_to_missing?(symbol, include_private)
    is_translation_method?(symbol.to_s) || super
  end
  
  def is_translation_method?(symbol)
    symbol.match(/^(name|hint)_([a-z]{3})(_before_type_cast)?(=?)$/)
  end
  
  # hack so the validation message will look right
  def english_name; name_eng; end
  
  def name(lang = nil); translation_for(:name, lang); end
  def name=(lang, value); set_translation_for(:name, lang, value); end
  def hint(lang = nil); translation_for(:hint, lang); end
  def hint=(lang, value); set_translation_for(:hint, lang, value); end

  def options
    option_set ? option_set.sorted_options : nil
  end
  def is_select?
    type && type.name.match(/^select/)
  end
  def select_options
    (opt = options) ? opt.collect{|o| [o.name, o.id]} : []
  end
  def is_location?
    type.name == "location"
  end
  def is_address?
    type.name == "address"
  end
  def published?
    !forms.detect{|f| f.published?}.nil?
  end
  
  # an odk-friendly unique code
  def odk_code
    "q#{id}"
  end
  
  # shortcut method for tests
  def qing_ids
    questionings.collect{|qing| qing.id}
  end
  
  private
    def integrity
      # error if type or option set have changed and there are answers or conditions
      if (question_type_id_changed? || option_set_id_changed?) 
        if !answers.empty?
          errors.add(:base, "Type or option set can't be changed because there are already responses for this question")
        elsif !referring_conditions.empty?
          errors.add(:base, "Type or option set can't be changed because there are conditions that refer to this question")
        end
      end
      # error if anything has changed and the question is published
      if published? && (changed? || translations.detect{|t| t.changed?})
        errors.add(:base, "Can't be changed because it appears in at least one published form")
      end
    end
    def check_assoc
      unless questionings.empty?
        raise("You can't delete question '#{code}' because it is included in at least one form")
      end
    end
end
