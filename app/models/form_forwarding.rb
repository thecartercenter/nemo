class FormForwarding < ApplicationRecord
  belongs_to :form
  belongs_to :recipient, polymorphic: true
end
