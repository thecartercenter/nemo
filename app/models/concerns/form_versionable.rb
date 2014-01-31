# common methods for classes that need to notify the FormVersioningPolicy when they are modified
module FormVersionable
  extend ActiveSupport::Concern

  included do
    before_create do
      FormVersioningPolicy.notify(self, :create) if versionable?
      return true
    end

    before_save do
      FormVersioningPolicy.notify(self, :update) if versionable?
      return true
    end

    before_destroy do
      FormVersioningPolicy.notify(self, :destroy) if versionable?
      return true
    end
  end

  # returns whether a specific object is subject to the versioning policy
  # if this mixin is included, we know the overall class is subject to it
  # this is currently true iff the object is not standard
  def versionable?
    !respond_to?(:is_standard?) || !is_standard?
  end
end