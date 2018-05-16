# destroy objects in batches
class BatchDestroy
  attr_reader :batch, :current_user, :ability

  def initialize(batch, current_user, ability)
    @batch = batch
    @current_user = current_user
    @ability = ability
  end

  def destroy!
    skipped_current = batch.reject! { |u| u.id == current_user.id }
    begin
      skipped_users = []
      skipped_users << current_user if skipped_current

      destroyed_users = []
      deactivated_users = []
      User.transaction do
        batch.each do |u|
          begin
            raise DeletionError unless ability.can?(:destroy, u)

            u.destroy
            destroyed_users << u
          rescue DeletionError => e
            if u.active?
              u.activate!(false)
              deactivated_users << u
            else
              skipped_users << u
            end
          end
        end
      end
    end
    # return counts for destroyed, skipped and deactivated users
    {destroyed_count: destroyed_users.count,
     skipped_count: skipped_users.count,
     skipped_current: (true if skipped_users.include?(current_user)),
     deactivated_count: deactivated_users.count}
  end
end
