class FormForwarding < ActiveRecord::Base
  belongs_to :form
  belongs_to :forwardee, polymorphic: true
end
