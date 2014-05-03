class Whitelist < ActiveRecord::Base
  belongs_to :whitelistable, :polymorphic => true
  belongs_to :user
end
