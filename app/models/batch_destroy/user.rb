# frozen_string_literal: true

module BatchDestroy
  # Destroy User objects in batches
  class User < BatchDestroy::BatchDestroy
    def initialize(params)
      super(params)
      @user = params[:user]

      # Special case for users since we can't delete current user
      @skipped = []
      current_user = @rel.find { |u| u.id == @user.id }
      @skipped << current_user if current_user
    end
  end
end
