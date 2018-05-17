# destroy objects in batches
class BatchDestroy
  attr_reader :batch, :klass, :ability

  def initialize(batch, klass, ability)
    @batch = batch
    @klass = klass
    @ability = ability
  end

  def destroy!
    skipped = []
    deactivated = []
    destroyed = []

    # this batch destroyer is currently being used in User and Question indexes
    # the current user doesn't matter for question delete so this will only run if it is User bulk destroy
    if klass.is_a?(User)
      current_user = batch.find { |u| u.id == klass.id }
      skipped << current_user if current_user
    end

    begin
      User.transaction do
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
    {destroyed: destroyed.count,
     skipped: skipped.count,
     deactivated: deactivated.count}
  end
end
