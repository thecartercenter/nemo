class OptionNode < ActiveRecord::Base
  attr_accessible :ancestry, :option_id, :option_set_id, :rank
  has_ancestry
end
