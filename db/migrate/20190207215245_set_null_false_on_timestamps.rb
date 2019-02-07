# frozen_string_literal: true
class SetNullFalseOnTimestamps < ActiveRecord::Migration[5.2]
  def change
    change_column_null :answers, :created_at, false
    change_column_null :assignments, :created_at, false
    change_column_null :broadcast_addressings, :created_at, false
    change_column_null :broadcasts, :created_at, false
    change_column_null :choices, :created_at, false
    change_column_null :conditions, :created_at, false
    change_column_null :delayed_jobs, :created_at, false
    change_column_null :form_items, :created_at, false
    change_column_null :forms, :created_at, false
    change_column_null :missions, :created_at, false
    change_column_null :option_sets, :created_at, false
    change_column_null :options, :created_at, false
    change_column_null :questions, :created_at, false
    change_column_null :report_calculations, :created_at, false
    change_column_null :report_reports, :created_at, false
    change_column_null :responses, :created_at, false
    change_column_null :sessions, :created_at, false
    change_column_null :settings, :created_at, false

    change_column_null :answers, :updated_at, false
    change_column_null :assignments, :updated_at, false
    change_column_null :broadcast_addressings, :updated_at, false
    change_column_null :broadcasts, :updated_at, false
    change_column_null :choices, :updated_at, false
    change_column_null :conditions, :updated_at, false
    change_column_null :delayed_jobs, :updated_at, false
    change_column_null :form_items, :updated_at, false
    change_column_null :forms, :updated_at, false
    change_column_null :missions, :updated_at, false
    change_column_null :option_sets, :updated_at, false
    change_column_null :options, :updated_at, false
    change_column_null :questions, :updated_at, false
    change_column_null :report_calculations, :updated_at, false
    change_column_null :report_reports, :updated_at, false
    change_column_null :responses, :updated_at, false
    change_column_null :sessions, :updated_at, false
    change_column_null :settings, :updated_at, false
  end
end
