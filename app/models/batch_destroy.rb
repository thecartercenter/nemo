# frozen_string_literal: true

# Destroy objects in batches
class BatchDestroy
  attr_reader :batch, :user, :ability

  def initialize(batch, user, ability)
    @batch = batch
    @user = user
    @ability = ability
  end

  def destroy!
    skipped = []
    deactivated = []
    destroyed = []

    # Special case for User deletion because we can't delete the current user!
    if batch[0].is_a?(User)
      current_user = batch.find { |u| u.id == user.id }
      skipped << current_user if current_user
    end

    begin
      ActiveRecord::Base.transaction do
        batch.each do |object|
          # if it is a user bulk destroy, it will be the first value in the skipped array
          next if object == skipped.first

          begin
            raise DeletionError unless ability.can?(:destroy, object)

            object.destroy
            destroyed << object
          rescue DeletionError
            if object.try(:active?)
              object.activate!(false)
              deactivated << object
            else
              skipped << object
            end
          end
        end
      end
    end

    # return counts for destroyed, skipped and deactivated objects
    {destroyed: destroyed.count, skipped: skipped.count, deactivated: deactivated.count}
  end
end
