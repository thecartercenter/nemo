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
require 'seedable'
require 'language_list'
require 'mission_based'
class Language < ActiveRecord::Base
  include MissionBased
  include Seedable
  
  validates(:code, :presence => true, :uniqueness => true)
  validate(:english_mandatory)
  before_destroy(:check_assoc_and_english_mandatory)
  after_save(:rebuild_hash)
  
  has_many(:translations)
  has_many(:users)
  
  default_scope(order("code = 'eng' desc, code"))
  scope(:active, where(:active => true))
  
  def self.generate
    seed(:code, :code => "eng", :active => true)
  end
  
  def self.by_code(code)
    code_hash[code]
  end
  def self.code_hash(options = {})
    if !defined?(@@code_hash) || options[:rebuild]
      @@code_hash = Hash[*all.collect{|l| [l.code, l]}.flatten]
    end
    @@code_hash
  end
  def self.add_select_options
    LanguageList::LANGS.map{|code, name| [name, code]}.sort_by{|pair| pair[0]}
  end
  def self.english
    @@english ||= find_by_code("eng")
  end
  def is_english?
    code == "eng"
  end
  def name
    LanguageList::LANGS[code.to_sym]
  end
  
  private
    def english_mandatory
      if code_was == "eng"
        errors.add(:base, "You can't change English because it's the main system language.")
      end
      # English must always be active
      if self == self.class.english && !active
        errors.add(:active, "can't be false since English must always be active")
      end
    end
    def check_assoc_and_english_mandatory
      # Can't delete English
      if self == self.class.english
        raise("You can't delete #{name}.") 
      # Can't delete languages with related translations.
      elsif Translation.find_by_language_id(id)
        raise("You can't delete #{name} because it has associated translations. Try deactivating it.")
      end
    end
    def rebuild_hash
      self.class.code_hash(:rebuild => true)
    end
end
