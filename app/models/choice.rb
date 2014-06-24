class Choice < ActiveRecord::Base
  belongs_to(:answer, :inverse_of => :choices, :touch => true)
  belongs_to(:option, :inverse_of => :choices)

  delegate :name, :to => :option, :prefix => true

  attr_accessor :checked
end
