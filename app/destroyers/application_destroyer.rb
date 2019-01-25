# frozen_string_literal: true

# Abstract class for destroying objects in batches.
# Responsible for checking permissions for destruction (based on given Ability) and
# handling any DeletionErrors raised during deletion.
class ApplicationDestroyer
  attr_accessor :rel, :ability, :skipped, :destroyed, :deactivated

  def initialize(params)
    self.rel = params[:rel]
    self.ability = params[:ability]
    self.deactivated = []
    self.destroyed = []
    self.skipped = []
  end

  def destroy!
    ActiveRecord::Base.transaction do
      rel.each do |object|
        next if handle_explicit_skip(object)
        begin
          raise DeletionError unless ability.can?(:destroy, object)
          object.destroy
          destroyed << object
        rescue DeletionError
          handle_error(object)
        end
      end
    end
    {destroyed: destroyed.count, skipped: skipped.count, deactivated: deactivated.count}
  end

  protected

  def can_deactivate?
    false
  end

  def skip?(_)
    false
  end

  private

  def handle_explicit_skip(object)
    return unless skip?(object)
    skipped << object
    true
  end

  def handle_error(object)
    if can_deactivate?
      object.activate!(false)
      deactivated << object
    else
      skipped << object
    end
  end
end
