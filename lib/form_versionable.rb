# common methods for classes that need to notify the FormVersioningPolicy when they are modified
module FormVersionable
  def notify_form_versioning_policy_of_create
    FormVersioningPolicy.notify(self, :create)
    return true
  end

  def notify_form_versioning_policy_of_update
    FormVersioningPolicy.notify(self, :update)
    return true
  end

  def notify_form_versioning_policy_of_destroy
    FormVersioningPolicy.notify(self, :destroy)
    return true
  end
end