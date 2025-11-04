# frozen_string_literal: true

# == Schema Information
#
# Table name: custom_dashboards
#
#  id          :uuid             not null, primary key
#  name        :string(255)      not null
#  description :text
#  layout      :jsonb
#  settings    :jsonb
#  is_public   :boolean          default(FALSE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  mission_id  :uuid
#  user_id     :uuid
#
# Indexes
#
#  index_custom_dashboards_on_mission_id  (mission_id)
#  index_custom_dashboards_on_user_id     (user_id)
#

class CustomDashboard < ApplicationRecord
  include MissionBased

  belongs_to :user
  belongs_to :mission
  has_many :dashboard_widgets, dependent: :destroy

  validates :name, presence: true, length: { maximum: 255 }
  validates :layout, presence: true
  validates :settings, presence: true

  scope :public_dashboards, -> { where(is_public: true) }
  scope :user_dashboards, ->(user) { where(user: user) }
  scope :accessible_by, ->(ability) { 
    where(
      "is_public = true OR user_id = ?", 
      ability.user&.id
    )
  }

  WIDGET_TYPES = %w[
    response_chart
    form_stats
    user_activity
    geographic_map
    completion_rate
    response_trends
    form_performance
    custom_query
    text_widget
    image_widget
  ].freeze

  def widgets
    dashboard_widgets.order(:position)
  end

  def add_widget(widget_type, config = {})
    position = dashboard_widgets.maximum(:position).to_i + 1
    
    dashboard_widgets.create!(
      widget_type: widget_type,
      config: config,
      position: position
    )
  end

  def remove_widget(widget_id)
    widget = dashboard_widgets.find(widget_id)
    widget.destroy
    
    # Reorder remaining widgets
    dashboard_widgets.where('position > ?', widget.position)
                    .update_all('position = position - 1')
  end

  def reorder_widgets(widget_ids)
    widget_ids.each_with_index do |widget_id, index|
      dashboard_widgets.find(widget_id).update!(position: index + 1)
    end
  end

  def duplicate_for_user(new_user)
    new_dashboard = dup
    new_dashboard.user = new_user
    new_dashboard.name = "#{name} (Copy)"
    new_dashboard.is_public = false
    new_dashboard.save!

    # Copy widgets
    dashboard_widgets.each do |widget|
      new_dashboard.dashboard_widgets.create!(
        widget_type: widget.widget_type,
        config: widget.config,
        position: widget.position
      )
    end

    new_dashboard
  end

  def export_config
    {
      name: name,
      description: description,
      layout: layout,
      settings: settings,
      widgets: widgets.map do |widget|
        {
          type: widget.widget_type,
          config: widget.config,
          position: widget.position
        }
      end
    }
  end

  def self.import_config(config, user, mission)
    dashboard = create!(
      name: config[:name],
      description: config[:description],
      layout: config[:layout],
      settings: config[:settings],
      user: user,
      mission: mission,
      is_public: false
    )

    config[:widgets]&.each do |widget_config|
      dashboard.dashboard_widgets.create!(
        widget_type: widget_config[:type],
        config: widget_config[:config],
        position: widget_config[:position]
      )
    end

    dashboard
  end
end