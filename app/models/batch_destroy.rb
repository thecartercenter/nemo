# destroy objects in batches
class BatchDestroy
  attr_reader :batch, :user, :ability

  def initialize(batch, user, ability)
    @batch = batch
    @user = user
    @ability = ability
  end

  def destroy!
    skipped_users = []
    destroyed_users = []
    deactivated_users = []

    current_user = batch.find { |u| u.id == user.id }
    begin
      skipped_users << current_user if current_user

      User.transaction do
        batch.each do |u|
          next if u == current_user
          begin
            raise DeletionError unless ability.can?(:destroy, u)

            u.destroy
            destroyed_users << u
          rescue DeletionError
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
    {destroyed: destroyed_users.count,
     skipped: skipped_users.count,
     skipped_current: skipped_users.count == 1,
     deactivated: deactivated_users.count}
  end
end
