class Group < ActiveRecord::Base
  include MissionBased

  has_many :user_groups, :dependent => :destroy
  has_many :users, :through => :user_groups

  validates :mission, :presence => true
end
