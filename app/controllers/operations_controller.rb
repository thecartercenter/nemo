class OperationsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  def index
    @operations = @operations.order(created_at: :desc)
  end

  def show
  end

  def destroy
    destroy_and_handle_errors(@operation)
    redirect_to(index_url_with_context)
  end

  def clear
    @operations.each do |op|
      op.destroy if can?(:destroy, op)
    end

    redirect_to(index_url_with_context)
  end
end
