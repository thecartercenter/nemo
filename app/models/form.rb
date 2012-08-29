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
class Form < ActiveRecord::Base
  include MissionBased

  has_many(:questions, :through => :questionings)
  has_many(:questionings, :order => "rank", :autosave => true, :dependent => :destroy)
  has_many(:responses)
  belongs_to(:type, :class_name => "FormType", :foreign_key => :form_type_id)
  
  validates(:name, :presence => true, :uniqueness => true, :length => {:maximum => 32})
  validates(:type, :presence => true)
  validate(:cant_change_published)
  
  validates_associated(:questionings)
  
  before_save(:fix_ranks)
  before_create(:init_downloads)
  before_destroy(:check_assoc)
  
  # no pagination
  self.per_page = 1000000
  
  default_scope(order("form_types.name, forms.name").includes(:type))
  scope(:published, where(:published => true))
  scope(:with_questions, includes(:type, {:questionings => [:form, :condition, {:question => 
    [:type, :translations, :option_set]}]}).order("questionings.rank"))
  
  # finds the highest 'version' number of all forms with the given base name
  # returns nil if no forms found
  def self.max_version(base_name)
    mv = all.collect{|f| m = f.name.match(/^#{base_name}( v(\d+))?$/); m ? (m[2] ? m[2].to_i : 1) : 0}.max
    mv == 0 ? nil : mv
  end
  
  def temp_response_id
    "#{name}_#{ActiveSupport::SecureRandom.random_number(899999999) + 100000000}"
  end
  
  def version
    "1.0" # this isn't implemented yet
  end
  
  def full_name
    "#{type.name}: #{name}"
  end
  
  def option_sets
    questions.collect{|q| q.option_set}.compact.uniq
  end
  
  def visible_questionings
    questionings.reject{|q| q.hidden}
  end
  
  def max_rank
    questionings.map{|qing| qing.rank}.max || 0
  end
  
  def update_ranks(new_ranks)
    transaction do 
      questionings.each{|qing| qing.update_rank(new_ranks[qing.id.to_s].to_i) if new_ranks[qing.id.to_s]}
      questionings.each{|qing| qing.verify_condition_ordering}
    end
  end
  
  def destroy_questionings(qings)
    transaction do
      qings.each do |qing|
        questionings.delete(qing)
        qing.destroy
      end
      save
    end
  end
  
  def toggle_published
    self.published = !self.published?
    self.downloads = 0
    save
  end
  
  def add_download
    self.downloads += 1
    save
  end
  
  # makes a copy of the form, with a new name and a new set of questionings
  def duplicate
    # get the base name
    base = name.match(/^(.+?)( v(\d+))?$/)[1]
    version = (self.class.max_version(base) || 1) + 1
    # create the new form and set the basic attribs
    cloned = self.class.new(:name => "#{base} v#{version}", :published => false, :form_type_id => form_type_id)
    # clone all the questionings
    cloned.questionings = Questioning.duplicate(questionings)
    # done!
    cloned.save
  end
  
  private
    def cant_change_published
      # if this is a published form and something other than published and downloads changes, wrong!
      if published_was && !(changed - %w[published downloads]).empty?
        errors.add(:base, "A published form can't be edited.") 
      end
    end
    def fix_ranks
      questionings.each_index{|i| questionings[i].rank = i + 1}
      return true
    end
    def init_downloads
      self.downloads = 0
      return true
    end
    def check_assoc
      if published?
        raise "You can't delete form '#{name}' because it is published."
      elsif !responses.empty?
        raise "You can't delete form '#{name}' because it has associated responses."
      end
    end
end
