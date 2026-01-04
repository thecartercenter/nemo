# frozen_string_literal: true

class CustomDashboardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mission
  before_action :set_dashboard, only: %i[show edit update destroy duplicate export widgets]

  def index
    authorize!(:view, :custom_dashboards)

    @dashboards = CustomDashboard.accessible_by(current_ability)
      .where(mission: @mission)
      .includes(:user, :dashboard_widgets)
      .order(created_at: :desc)
      .paginate(page: params[:page], per_page: 20)
  end

  def show
    authorize!(:view, @dashboard)

    @widgets_data = {}
    @dashboard.widgets.each do |widget|
      @widgets_data[widget.id] = widget.render_data(@mission, current_user)
    end
  end

  def new
    authorize!(:create, :custom_dashboard)

    @dashboard = CustomDashboard.new(mission: @mission, user: current_user)
    @available_widgets = CustomDashboard::WIDGET_TYPES
  end

  def edit
    authorize!(:update, @dashboard)

    @available_widgets = CustomDashboard::WIDGET_TYPES
  end

  def create
    authorize!(:create, :custom_dashboard)

    @dashboard = CustomDashboard.new(dashboard_params.merge(mission: @mission, user: current_user))

    if @dashboard.save
      redirect_to(custom_dashboard_path(@dashboard), notice: "Dashboard was successfully created.")
    else
      @available_widgets = CustomDashboard::WIDGET_TYPES
      render(:new)
    end
  end

  def update
    authorize!(:update, @dashboard)

    if @dashboard.update(dashboard_params)
      redirect_to(custom_dashboard_path(@dashboard), notice: "Dashboard was successfully updated.")
    else
      @available_widgets = CustomDashboard::WIDGET_TYPES
      render(:edit)
    end
  end

  def destroy
    authorize!(:destroy, @dashboard)

    @dashboard.destroy
    redirect_to(custom_dashboards_path, notice: "Dashboard was successfully deleted.")
  end

  def duplicate
    authorize!(:create, :custom_dashboard)

    new_dashboard = @dashboard.duplicate_for_user(current_user)
    redirect_to(custom_dashboard_path(new_dashboard), notice: "Dashboard was successfully duplicated.")
  end

  def export
    authorize!(:view, @dashboard)

    config = @dashboard.export_config
    filename = "#{@dashboard.name.parameterize}_dashboard.json"

    respond_to do |format|
      format.json do
        send_data(config.to_json,
          filename: filename,
          type: "application/json",
          disposition: "attachment")
      end
    end
  end

  def import
    authorize!(:create, :custom_dashboard)

    if params[:config_file].present?
      begin
        config = JSON.parse(params[:config_file].read)
        @dashboard = CustomDashboard.import_config(config, current_user, @mission)
        redirect_to(custom_dashboard_path(@dashboard), notice: "Dashboard was successfully imported.")
      rescue StandardError => e
        redirect_to(custom_dashboards_path, alert: "Import failed: #{e.message}")
      end
    else
      redirect_to(custom_dashboards_path, alert: "No file selected.")
    end
  end

  def widgets
    authorize!(:view, @dashboard)

    @widgets = @dashboard.widgets
    @widgets_data = {}

    @widgets.each do |widget|
      @widgets_data[widget.id] = widget.render_data(@mission, current_user)
    end

    render(json: {
      widgets: @widgets.map do |widget|
        {
          id: widget.id,
          type: widget.widget_type,
          title: widget.title,
          position: widget.position,
          data: @widgets_data[widget.id]
        }
      end
    })
  end

  def add_widget
    @dashboard = CustomDashboard.find(params[:dashboard_id])
    authorize!(:update, @dashboard)

    widget_type = params[:widget_type]
    config = params[:config] || {}

    widget = @dashboard.add_widget(widget_type, config)

    render(json: {
      id: widget.id,
      type: widget.widget_type,
      title: widget.title,
      position: widget.position,
      data: widget.render_data(@mission, current_user)
    })
  end

  def remove_widget
    @dashboard = CustomDashboard.find(params[:dashboard_id])
    authorize!(:update, @dashboard)

    @dashboard.remove_widget(params[:widget_id])

    render(json: {success: true})
  end

  def reorder_widgets
    @dashboard = CustomDashboard.find(params[:dashboard_id])
    authorize!(:update, @dashboard)

    widget_ids = params[:widget_ids]
    @dashboard.reorder_widgets(widget_ids)

    render(json: {success: true})
  end

  private

  def set_mission
    @mission = current_mission
  end

  def set_dashboard
    @dashboard = CustomDashboard.find(params[:id])
  end

  def dashboard_params
    params.require(:custom_dashboard).permit(
      :name, :description, :is_public,
      layout: %i[columns theme], settings: %i[refresh_interval show_legend]
    )
  end
end
