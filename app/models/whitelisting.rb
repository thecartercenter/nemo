class Whitelisting < ApplicationRecord
  belongs_to :whitelistable, :polymorphic => true
  belongs_to :user
end
