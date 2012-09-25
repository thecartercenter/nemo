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
require 'mission_based'
class OptionSet < ActiveRecord::Base
  include MissionBased

  has_many(:option_settings, :dependent => :destroy, :autosave => true, :inverse_of => :option_set)
  has_many(:options, :through => :option_settings)
  has_many(:questions, :inverse_of => :option_set)
  has_many(:questionings, :through => :questions)
  
  validates(:name, :presence => true, :uniqueness => true)
  validates(:ordering, :presence => true)
  validates_associated(:option_settings)
  validate(:at_least_one_option)
  validate(:unique_values)
  
  before_destroy(:check_assoc)
  
  default_scope(order("name"))
  
  self.per_page = 100

  def self.orderings
    [{:code => "value_asc", :name => "Value Low to High", :sql => "value asc"},
     {:code => "value_desc", :name => "Value High to Low", :sql => "value desc"}]
  end
  
  def self.ordering_select_options
    orderings.collect{|o| [o[:name], o[:code]]}
  end
  
  def sorted_options
    @sorted_options ||= options.sort{|a,b| (a.value.to_i <=> b.value.to_i) * (ordering && ordering.match(/desc/) ? -1 : 1)}
  end
  
  def published?
    # check for any published questionings
    !questionings.detect{|qing| qing.published?}.nil?
  end
  
  # finds or initializes an option_setting for every option in the database (never meant to be saved)
  def all_option_settings
    # make sure there is an associated answer object for each questioning in the form
    Option.all.collect{|o| option_setting_for(o) || option_settings.new(:option_id => o.id, :included => false)}
  end
  
  def all_option_settings=(params)
    # create a bunch of temp objects, discarding any unchecked options
    submitted = params.values.collect{|p| p[:included] == '1' ? OptionSetting.new(p) : nil}.compact
    
    # copy new choices into old objects, creating or deleting if necessary
    option_settings.match(submitted, Proc.new{|os| os.option_id}) do |orig, subd|
      # if both exist, do nothing
      # if submitted is nil, destroy the original
      if subd.nil?
        option_settings.delete(orig)
      # if original is nil, add the new one to this option_set's array
      elsif orig.nil?
        option_settings << subd
      end
    end
  end
    
  def option_setting_for(option)
    # get the matching option_setting
    option_setting_hash[option]
  end

  def option_setting_hash(options = {})
    @option_setting_hash = nil if options[:rebuild]
    @option_setting_hash ||= Hash[*option_settings.collect{|os| [os.option, os]}.flatten]
  end
  
  private
    def at_least_one_option
      errors.add(:base, "You must choose at least one option.") if option_settings.empty?
    end
    def check_assoc
      unless questions.empty?
        raise "You can't delete option set '#{name}' because one or more questions are associated with it."
      end
    end
    def unique_values
      values = option_settings.map{|o| o.option.value}
      Rails.logger.info(values)
      if values.uniq.size != values.size
        errors.add(:base, "Two or more of the options you've chosen have the same numeric value.")
      end
    end
end
