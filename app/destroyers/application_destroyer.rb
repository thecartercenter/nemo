# frozen_string_literal: true

# Abstract class for destroying objects in batches either by enumerating or by SQL.
# Responsible for checking permissions for destruction (based on given Ability) and
# handling any DeletionErrors raised during deletion.
class ApplicationDestroyer
  def initialize(scope:, ability: nil)
    self.scope = scope
    self.ability = ability
    self.counts = {destroyed: 0, skipped: 0, deactivated: 0}
  end

  def destroy!
    ActiveRecord::Base.transaction do
      do_destroy
    end
    counts
  end

  protected

  attr_accessor :scope, :ability, :counts

  def can_deactivate?
    false
  end
end
