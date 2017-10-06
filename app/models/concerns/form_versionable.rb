# common methods for classes that need to notify the FormVersioningPolicy when they are modified
module FormVersionable
  extend ActiveSupport::Concern

  included do
    after_create do
      FormVersioningPolicy.new.notify(self, :create)
      true
    end

    after_save do
      FormVersioningPolicy.new.notify(self, :update)
      true
    end

    after_destroy do
      FormVersioningPolicy.new.notify(self, :destroy)
      true
    end
  end
end
