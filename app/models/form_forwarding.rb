class FormForwarding < ActiveRecord::Base
  belongs_to :form
  belongs_to :recipient, polymorphic: true
end
