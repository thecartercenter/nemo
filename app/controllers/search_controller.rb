# frozen_string_literal: true

class SearchController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mission

  def index
    authorize!(:search, :data)

    @search_service = SearchService.new(
      query: params[:q],
      mission: @mission,
      user: current_user,
      search_type: params[:type] || "all",
      filters: search_filters,
      sort: params[:sort],
      page: params[:page],
      per_page: params[:per_page] || 20
    )

    @results = @search_service.search
    @suggestions = @search_service.suggestions

    # Get filter options
    @forms = Form.accessible_by(current_ability).where(mission: @mission)
    @users = User.joins(:assignments).where(assignments: {mission: @mission})
    @search_types = SearchService::SEARCH_TYPES
    @sort_options = SearchService::SORT_OPTIONS

    respond_to do |format|
      format.html
      format.json { render(json: @results) }
    end
  end

  def suggestions
    authorize!(:search, :data)

    search_service = SearchService.new(
      query: params[:q],
      mission: @mission,
      user: current_user
    )

    suggestions = search_service.suggestions

    render(json: {suggestions: suggestions})
  end

  def advanced
    authorize!(:search, :data)

    @search_service = SearchService.new(
      mission: @mission,
      user: current_user,
      search_type: params[:type] || "all",
      filters: search_filters,
      sort: params[:sort],
      page: params[:page],
      per_page: params[:per_page] || 20
    )

    @forms = Form.accessible_by(current_ability).where(mission: @mission)
    @users = User.joins(:assignments).where(assignments: {mission: @mission})
    @search_types = SearchService::SEARCH_TYPES
    @sort_options = SearchService::SORT_OPTIONS
  end

  def results
    authorize!(:search, :data)

    @search_service = SearchService.new(
      query: params[:q],
      mission: @mission,
      user: current_user,
      search_type: params[:type] || "all",
      filters: search_filters,
      sort: params[:sort],
      page: params[:page],
      per_page: params[:per_page] || 20
    )

    @results = @search_service.search

    render(partial: "results")
  end

  private

  def set_mission
    @mission = current_mission
  end

  def search_filters
    {
      form_ids: params[:form_ids],
      user_ids: params[:user_ids],
      sources: params[:sources],
      incomplete: params[:incomplete],
      reviewed: params[:reviewed],
      status: params[:status],
      smsable: params[:smsable],
      active: params[:active],
      roles: params[:roles],
      report_types: params[:report_types],
      comment_types: params[:comment_types],
      resolved: params[:resolved],
      date_from: params[:date_from],
      date_to: params[:date_to]
    }.compact
  end
end
