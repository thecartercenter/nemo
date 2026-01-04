# frozen_string_literal: true

class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mission

  def dashboard
    authorize!(:view, :analytics)

    @time_range = params[:time_range] || "30_days"
    @start_date, @end_date = calculate_date_range(@time_range)

    @analytics_data = {
      response_trends: response_trends_data,
      form_performance: form_performance_data,
      user_activity: user_activity_data,
      geographic_distribution: geographic_distribution_data,
      completion_rates: completion_rates_data,
      response_sources: response_sources_data
    }

    respond_to do |format|
      format.html
      format.json { render(json: @analytics_data) }
    end
  end

  def response_trends
    authorize!(:view, :analytics)

    @time_range = params[:time_range] || "30_days"
    @start_date, @end_date = calculate_date_range(@time_range)

    render(json: response_trends_data)
  end

  def form_performance
    authorize!(:view, :analytics)

    render(json: form_performance_data)
  end

  def geographic_data
    authorize!(:view, :analytics)

    render(json: geographic_distribution_data)
  end

  private

  def set_mission
    @mission = current_mission
  end

  def calculate_date_range(time_range)
    case time_range
    when "7_days"
      [7.days.ago.beginning_of_day, Time.current.end_of_day]
    when "30_days"
      [30.days.ago.beginning_of_day, Time.current.end_of_day]
    when "90_days"
      [90.days.ago.beginning_of_day, Time.current.end_of_day]
    when "1_year"
      [1.year.ago.beginning_of_day, Time.current.end_of_day]
    else
      [30.days.ago.beginning_of_day, Time.current.end_of_day]
    end
  end

  def response_trends_data
    responses = Response.accessible_by(current_ability)
      .where(created_at: @start_date..@end_date)
      .group_by_day(:created_at)
      .count

    # Fill in missing days with zero counts
    (@start_date.to_date..@end_date.to_date).map do |date|
      {
        date: date.strftime("%Y-%m-%d"),
        count: responses[date] || 0
      }
    end
  end

  def form_performance_data
    forms = Form.accessible_by(current_ability)
      .joins(:responses)
      .where(responses: {created_at: @start_date..@end_date})
      .group("forms.id", "forms.name")
      .select("forms.id, forms.name, COUNT(responses.id) as response_count, AVG(CASE WHEN responses.incomplete = false THEN 1 ELSE 0 END) as completion_rate")

    forms.map do |form|
      {
        id: form.id,
        name: form.name,
        response_count: form.response_count,
        completion_rate: (form.completion_rate * 100).round(2)
      }
    end.sort_by { |form| -form[:response_count] }
  end

  def user_activity_data
    users = User.joins(:responses)
      .where(responses: {created_at: @start_date..@end_date})
      .group("users.id", "users.name")
      .select("users.id, users.name, COUNT(responses.id) as response_count")

    users.map do |user|
      {
        id: user.id,
        name: user.name,
        response_count: user.response_count
      }
    end.sort_by { |user| -user[:response_count] }
  end

  def geographic_distribution_data
    ResponseNode.for_mission(@mission)
      .where.not(latitude: nil, longitude: nil)
      .where(created_at: @start_date..@end_date)
      .select(:latitude, :longitude, :response_id)
      .limit(1000) # Limit for performance
      .map do |node|
      {
        lat: node.latitude.to_f,
        lng: node.longitude.to_f,
        response_id: node.response_id
      }
    end
  end

  def completion_rates_data
    total_responses = Response.accessible_by(current_ability)
      .where(created_at: @start_date..@end_date)
      .count

    completed_responses = Response.accessible_by(current_ability)
      .where(created_at: @start_date..@end_date)
      .where(incomplete: false)
      .count

    {
      total: total_responses,
      completed: completed_responses,
      completion_rate: total_responses > 0 ? (completed_responses.to_f / total_responses * 100).round(2) : 0
    }
  end

  def response_sources_data
    Response.accessible_by(current_ability)
      .where(created_at: @start_date..@end_date)
      .group(:source)
      .count
      .map do |source, count|
      {
        source: source.humanize,
        count: count
      }
    end
  end
end
