# handles the dashboard view. plural name just because of Rails convention.
class DashboardController < ApplicationController
  def show
    authorize!(:read, Dashboard)
  end
end