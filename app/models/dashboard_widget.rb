# frozen_string_literal: true

# == Schema Information
#
# Table name: dashboard_widgets
#
#  id                  :uuid             not null, primary key
#  custom_dashboard_id :uuid             not null
#  widget_type         :string(255)      not null
#  config              :jsonb
#  position            :integer          not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_dashboard_widgets_on_custom_dashboard_id  (custom_dashboard_id)
#  index_dashboard_widgets_on_position             (position)
#

class DashboardWidget < ApplicationRecord
  belongs_to :custom_dashboard

  validates :widget_type, presence: true, inclusion: { in: CustomDashboard::WIDGET_TYPES }
  validates :position, presence: true, numericality: { greater_than: 0 }
  validates :config, presence: true

  scope :ordered, -> { order(:position) }

  def title
    config['title'] || default_title
  end

  def size
    config['size'] || 'medium'
  end

  def refresh_interval
    config['refresh_interval'] || 300 # 5 minutes
  end

  def data_source
    config['data_source'] || {}
  end

  def chart_config
    config['chart_config'] || {}
  end

  def render_data(mission, user)
    case widget_type
    when 'response_chart'
      render_response_chart_data(mission, user)
    when 'form_stats'
      render_form_stats_data(mission, user)
    when 'user_activity'
      render_user_activity_data(mission, user)
    when 'geographic_map'
      render_geographic_map_data(mission, user)
    when 'completion_rate'
      render_completion_rate_data(mission, user)
    when 'response_trends'
      render_response_trends_data(mission, user)
    when 'form_performance'
      render_form_performance_data(mission, user)
    when 'custom_query'
      render_custom_query_data(mission, user)
    when 'text_widget'
      render_text_widget_data
    when 'image_widget'
      render_image_widget_data
    else
      { error: 'Unknown widget type' }
    end
  end

  private

  def default_title
    widget_type.humanize.titleize
  end

  def render_response_chart_data(mission, user)
    time_range = data_source['time_range'] || '30_days'
    start_date, end_date = calculate_date_range(time_range)
    
    responses = Response.accessible_by(user.ability)
                       .where(mission: mission)
                       .where(created_at: start_date..end_date)
                       .group_by_day(:created_at)
                       .count

    {
      type: 'line',
      data: {
        labels: responses.keys.map { |date| date.strftime('%Y-%m-%d') },
        datasets: [{
          label: 'Responses',
          data: responses.values,
          borderColor: '#007bff',
          backgroundColor: 'rgba(0, 123, 255, 0.1)'
        }]
      },
      options: chart_config
    }
  end

  def render_form_stats_data(mission, user)
    forms = Form.accessible_by(user.ability)
                .where(mission: mission)
                .joins(:responses)
                .group('forms.id', 'forms.name')
                .select('forms.id, forms.name, COUNT(responses.id) as response_count')

    {
      type: 'bar',
      data: {
        labels: forms.map(&:name),
        datasets: [{
          label: 'Response Count',
          data: forms.map(&:response_count),
          backgroundColor: '#28a745'
        }]
      },
      options: chart_config
    }
  end

  def render_user_activity_data(mission, user)
    users = User.joins(:responses, :assignments)
                .where(assignments: { mission: mission })
                .where(responses: { mission: mission })
                .group('users.id', 'users.name')
                .select('users.id, users.name, COUNT(responses.id) as response_count')
                .order('response_count DESC')
                .limit(10)

    {
      type: 'horizontalBar',
      data: {
        labels: users.map(&:name),
        datasets: [{
          label: 'Responses',
          data: users.map(&:response_count),
          backgroundColor: '#17a2b8'
        }]
      },
      options: chart_config
    }
  end

  def render_geographic_map_data(mission, user)
    locations = ResponseNode.for_mission(mission)
                           .where.not(latitude: nil, longitude: nil)
                           .select(:latitude, :longitude, :response_id)
                           .limit(1000)

    {
      type: 'map',
      data: locations.map do |location|
        {
          lat: location.latitude.to_f,
          lng: location.longitude.to_f,
          response_id: location.response_id
        }
      end
    }
  end

  def render_completion_rate_data(mission, user)
    time_range = data_source['time_range'] || '30_days'
    start_date, end_date = calculate_date_range(time_range)
    
    total_responses = Response.accessible_by(user.ability)
                             .where(mission: mission)
                             .where(created_at: start_date..end_date)
                             .count

    completed_responses = Response.accessible_by(user.ability)
                                 .where(mission: mission)
                                 .where(created_at: start_date..end_date)
                                 .where(incomplete: false)
                                 .count

    completion_rate = total_responses > 0 ? (completed_responses.to_f / total_responses * 100).round(2) : 0

    {
      type: 'gauge',
      data: {
        value: completion_rate,
        max: 100,
        label: 'Completion Rate (%)'
      },
      options: chart_config
    }
  end

  def render_response_trends_data(mission, user)
    time_range = data_source['time_range'] || '30_days'
    start_date, end_date = calculate_date_range(time_range)
    
    trends = Response.accessible_by(user.ability)
                    .where(mission: mission)
                    .where(created_at: start_date..end_date)
                    .group_by_day(:created_at)
                    .count

    # Calculate trend direction
    first_half = trends.values[0..(trends.values.length / 2 - 1)].sum
    second_half = trends.values[(trends.values.length / 2)..-1].sum
    trend_direction = second_half > first_half ? 'up' : 'down'
    trend_percentage = first_half > 0 ? ((second_half - first_half).to_f / first_half * 100).round(2) : 0

    {
      type: 'trend',
      data: {
        current_value: trends.values.last || 0,
        previous_value: trends.values.first || 0,
        trend_direction: trend_direction,
        trend_percentage: trend_percentage,
        chart_data: trends.map { |date, count| { x: date.strftime('%Y-%m-%d'), y: count } }
      }
    }
  end

  def render_form_performance_data(mission, user)
    forms = Form.accessible_by(user.ability)
                .where(mission: mission)
                .joins(:responses)
                .group('forms.id', 'forms.name')
                .select('forms.id, forms.name, COUNT(responses.id) as response_count, AVG(CASE WHEN responses.incomplete = false THEN 1 ELSE 0 END) as completion_rate')

    {
      type: 'scatter',
      data: forms.map do |form|
        {
          x: form.response_count,
          y: (form.completion_rate * 100).round(2),
          label: form.name
        }
      end,
      options: {
        scales: {
          x: { title: 'Response Count' },
          y: { title: 'Completion Rate (%)' }
        }
      }
    }
  end

  def render_custom_query_data(mission, user)
    query = data_source['query']
    return { error: 'No query specified' } unless query.present?

    # This would execute a custom SQL query
    # In a real implementation, you'd want to sanitize and validate the query
    begin
      results = ActiveRecord::Base.connection.execute(query)
      {
        type: 'table',
        data: results.to_a
      }
    rescue => e
      { error: "Query execution failed: #{e.message}" }
    end
  end

  def render_text_widget_data
    {
      type: 'text',
      content: config['content'] || 'Text widget content'
    }
  end

  def render_image_widget_data
    {
      type: 'image',
      src: config['image_url'] || '/images/placeholder.png',
      alt: config['alt_text'] || 'Image widget'
    }
  end

  def calculate_date_range(time_range)
    case time_range
    when '7_days'
      [7.days.ago.beginning_of_day, Time.current.end_of_day]
    when '30_days'
      [30.days.ago.beginning_of_day, Time.current.end_of_day]
    when '90_days'
      [90.days.ago.beginning_of_day, Time.current.end_of_day]
    when '1_year'
      [1.year.ago.beginning_of_day, Time.current.end_of_day]
    else
      [30.days.ago.beginning_of_day, Time.current.end_of_day]
    end
  end
end