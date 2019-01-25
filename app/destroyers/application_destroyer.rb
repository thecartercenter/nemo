# frozen_string_literal: true

# Abstract class for destroying objects in batches.
# Responsible for checking permissions for destruction (based on given Ability) and
# handling any DeletionErrors raised during deletion.
class ApplicationDestroyer
  def initialize(params)
    self.scope = params[:scope]
    self.ability = params[:ability]
    self.counts = {destroyed: 0, skipped: 0, deactivated: 0}
  end

  def destroy!
    ActiveRecord::Base.transaction do
      scope.each do |object|
        next if handle_explicit_skip(object)
        begin
          raise DeletionError unless ability.can?(:destroy, object)
          object.destroy
          counts[:destroyed] += 1
        rescue DeletionError
          handle_error(object)
        end
      end
    end
    counts
  end

  protected

  attr_accessor :scope, :ability, :counts

  def can_deactivate?
    false
  end

  def skip?(_object)
    false
  end

  private

  def handle_explicit_skip(object)
    return unless skip?(object)
    counts[:skipped] += 1
    true
  end

  def handle_error(object)
    if can_deactivate?
      object.activate!(false)
      counts[:deactivated] += 1
    else
      counts[:skipped] += 1
    end
  end
end
