# common methods for classes that need to notify the FormVersioningPolicy when they are modified
module FormVersionable
  extend ActiveSupport::Concern

  included do
    after_create do
      FormVersioningPolicy.new.notify(self, :create) if versionable?
      true
    end

    after_save do
      FormVersioningPolicy.new.notify(self, :update) if versionable?
      true
    end

    after_destroy do
      FormVersioningPolicy.new.notify(self, :destroy) if versionable?
      true
    end
  end

  # returns whether a specific object is subject to the versioning policy
  # if this mixin is included, we know the overall class is subject to it
  # this is currently true iff the object is not standard
  def versionable?
    !respond_to?(:is_standard?) || !is_standard?
  end
end