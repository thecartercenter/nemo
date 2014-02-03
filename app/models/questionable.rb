class Questionable < ActiveRecord::Base
  include MissionBased, Standardizable, Replicable
end