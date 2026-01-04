# frozen_string_literal: true

class SearchService
  include ActiveModel::Model

  attr_accessor :query, :mission, :user, :search_type, :filters, :sort, :page, :per_page

  SEARCH_TYPES = %w[all responses forms users reports comments].freeze
  SORT_OPTIONS = %w[relevance date_asc date_desc name_asc name_desc].freeze

  validates :mission, presence: true
  validates :user, presence: true
  validates :search_type, inclusion: {in: SEARCH_TYPES}
  validates :sort, inclusion: {in: SORT_OPTIONS}, allow_blank: true

  def initialize(attributes = {})
    super
    @filters ||= {}
    @sort ||= "relevance"
    @page ||= 1
    @per_page ||= 20
  end

  def search
    return empty_results unless valid? && query.present?

    case search_type
    when "all"
      search_all
    when "responses"
      search_responses
    when "forms"
      search_forms
    when "users"
      search_users
    when "reports"
      search_reports
    when "comments"
      search_comments
    end
  end

  def suggestions
    return [] unless query.present? && query.length >= 2

    suggestions = []

    # Form suggestions
    form_suggestions = Form.accessible_by(user.ability)
      .where(mission: mission)
      .where("name ILIKE ?", "%#{query}%")
      .limit(5)
      .pluck(:name)

    suggestions.concat(form_suggestions.map { |name| {type: "form", text: name} })

    # User suggestions
    user_suggestions = User.joins(:assignments)
      .where(assignments: {mission: mission})
      .where("name ILIKE ?", "%#{query}%")
      .limit(5)
      .pluck(:name)

    suggestions.concat(user_suggestions.map { |name| {type: "user", text: name} })

    # Question suggestions
    question_suggestions = Question.joins(:questionings)
      .where(questionings: {form: Form.accessible_by(user.ability).where(mission: mission)})
      .where("name ILIKE ?", "%#{query}%")
      .limit(5)
      .pluck(:name)

    suggestions.concat(question_suggestions.map { |name| {type: "question", text: name} })

    suggestions.uniq.first(10)
  end

  private

  def search_all
    results = []

    # Search responses
    response_results = search_responses
    results.concat(response_results[:items].map { |item| item.merge(type: "response") })

    # Search forms
    form_results = search_forms
    results.concat(form_results[:items].map { |item| item.merge(type: "form") })

    # Search users
    user_results = search_users
    results.concat(user_results[:items].map { |item| item.merge(type: "user") })

    # Search reports
    report_results = search_reports
    results.concat(report_results[:items].map { |item| item.merge(type: "report") })

    # Sort by relevance
    results = sort_by_relevance(results)

    {
      items: results,
      total_count: results.length,
      search_type: "all"
    }
  end

  def search_responses
    responses = Response.accessible_by(user.ability)
      .where(mission: mission)
      .includes(:form, :user, :answers)

    # Apply text search
    if query.present?
      responses = responses.joins(:form, :user)
        .where(
          "responses.shortcode ILIKE ? OR forms.name ILIKE ? OR users.name ILIKE ? OR responses.reviewer_notes ILIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%"
        )
    end

    # Apply filters
    responses = apply_response_filters(responses)

    # Apply sorting
    responses = apply_sorting(responses, "responses")

    # Pagination
    responses = responses.paginate(page: page, per_page: per_page)

    {
      items: responses.map { |response| response_search_result(response) },
      total_count: responses.total_entries,
      search_type: "responses"
    }
  end

  def search_forms
    forms = Form.accessible_by(user.ability)
      .where(mission: mission)
      .includes(:questions, :responses)

    # Apply text search
    forms = forms.where("name ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%") if query.present?

    # Apply filters
    forms = apply_form_filters(forms)

    # Apply sorting
    forms = apply_sorting(forms, "forms")

    # Pagination
    forms = forms.paginate(page: page, per_page: per_page)

    {
      items: forms.map { |form| form_search_result(form) },
      total_count: forms.total_entries,
      search_type: "forms"
    }
  end

  def search_users
    users = User.joins(:assignments)
      .where(assignments: {mission: mission})
      .includes(:assignments)

    # Apply text search
    if query.present?
      users = users.where("name ILIKE ? OR login ILIKE ? OR email ILIKE ?", "%#{query}%", "%#{query}%", "%#{query}%")
    end

    # Apply filters
    users = apply_user_filters(users)

    # Apply sorting
    users = apply_sorting(users, "users")

    # Pagination
    users = users.paginate(page: page, per_page: per_page)

    {
      items: users.map { |user| user_search_result(user) },
      total_count: users.total_entries,
      search_type: "users"
    }
  end

  def search_reports
    reports = Report::Report.accessible_by(user.ability)
      .where(mission: mission)
      .includes(:creator)

    # Apply text search
    reports = reports.where("name ILIKE ?", "%#{query}%") if query.present?

    # Apply filters
    reports = apply_report_filters(reports)

    # Apply sorting
    reports = apply_sorting(reports, "reports")

    # Pagination
    reports = reports.paginate(page: page, per_page: per_page)

    {
      items: reports.map { |report| report_search_result(report) },
      total_count: reports.total_entries,
      search_type: "reports"
    }
  end

  def search_comments
    comments = Comment.joins(:response)
      .where(responses: {mission: mission})
      .includes(:author, :response)

    # Apply text search
    comments = comments.where("content ILIKE ?", "%#{query}%") if query.present?

    # Apply filters
    comments = apply_comment_filters(comments)

    # Apply sorting
    comments = apply_sorting(comments, "comments")

    # Pagination
    comments = comments.paginate(page: page, per_page: per_page)

    {
      items: comments.map { |comment| comment_search_result(comment) },
      total_count: comments.total_entries,
      search_type: "comments"
    }
  end

  def apply_response_filters(responses)
    responses = responses.where(form_id: filters[:form_ids]) if filters[:form_ids].present?
    responses = responses.where(user_id: filters[:user_ids]) if filters[:user_ids].present?
    responses = responses.where(source: filters[:sources]) if filters[:sources].present?
    responses = responses.where(incomplete: filters[:incomplete]) if filters[:incomplete].present?
    responses = responses.where(reviewed: filters[:reviewed]) if filters[:reviewed].present?

    if filters[:date_from].present?
      responses = responses.where("created_at >= ?", Date.parse(filters[:date_from]).beginning_of_day)
    end

    if filters[:date_to].present?
      responses = responses.where("created_at <= ?", Date.parse(filters[:date_to]).end_of_day)
    end

    responses
  end

  def apply_form_filters(forms)
    forms = forms.where(status: filters[:status]) if filters[:status].present?
    forms = forms.where(smsable: filters[:smsable]) if filters[:smsable].present?

    if filters[:date_from].present?
      forms = forms.where("created_at >= ?", Date.parse(filters[:date_from]).beginning_of_day)
    end

    forms = forms.where("created_at <= ?", Date.parse(filters[:date_to]).end_of_day) if filters[:date_to].present?

    forms
  end

  def apply_user_filters(users)
    users = users.where(active: filters[:active]) if filters[:active].present?
    users = users.joins(:assignments).where(assignments: {role: filters[:roles]}) if filters[:roles].present?

    users
  end

  def apply_report_filters(reports)
    reports = reports.where(type: filters[:report_types]) if filters[:report_types].present?

    if filters[:date_from].present?
      reports = reports.where("created_at >= ?", Date.parse(filters[:date_from]).beginning_of_day)
    end

    reports = reports.where("created_at <= ?", Date.parse(filters[:date_to]).end_of_day) if filters[:date_to].present?

    reports
  end

  def apply_comment_filters(comments)
    comments = comments.where(comment_type: filters[:comment_types]) if filters[:comment_types].present?
    comments = comments.where(is_resolved: filters[:resolved]) if filters[:resolved].present?

    if filters[:date_from].present?
      comments = comments.where("created_at >= ?", Date.parse(filters[:date_from]).beginning_of_day)
    end

    comments = comments.where("created_at <= ?", Date.parse(filters[:date_to]).end_of_day) if filters[:date_to].present?

    comments
  end

  def apply_sorting(records, _model_type)
    case sort
    when "date_asc"
      records.order(created_at: :asc)
    when "date_desc"
      records.order(created_at: :desc)
    when "name_asc"
      records.order(name: :asc)
    when "name_desc"
      records.order(name: :desc)
    else
      records.order(created_at: :desc)
    end
  end

  def sort_by_relevance(results)
    # Simple relevance scoring based on query matches
    results.sort_by do |result|
      score = 0
      query_words = query.downcase.split

      result_text = "#{result[:title]} #{result[:description]}".downcase

      query_words.each do |word|
        score += 3 if result_text.include?(word)
        score += 1 if result_text.include?(word[0..2]) # Partial match
      end

      -score # Negative for descending order
    end
  end

  def response_search_result(response)
    {
      id: response.id,
      title: "Response #{response.shortcode}",
      description: "Form: #{response.form.name} | User: #{response.user.name}",
      url: "/responses/#{response.id}",
      created_at: response.created_at,
      updated_at: response.updated_at,
      metadata: {
        form_name: response.form.name,
        user_name: response.user.name,
        source: response.source,
        incomplete: response.incomplete?,
        reviewed: response.reviewed?
      }
    }
  end

  def form_search_result(form)
    {
      id: form.id,
      title: form.name,
      description: form.description,
      url: "/forms/#{form.id}",
      created_at: form.created_at,
      updated_at: form.updated_at,
      metadata: {
        status: form.status,
        response_count: form.responses.count,
        question_count: form.questions.count
      }
    }
  end

  def user_search_result(user)
    assignment = user.assignments.find_by(mission: mission)
    {
      id: user.id,
      title: user.name,
      description: "#{user.email} | Role: #{assignment&.role || 'N/A'}",
      url: "/users/#{user.id}",
      created_at: user.created_at,
      updated_at: user.updated_at,
      metadata: {
        email: user.email,
        role: assignment&.role,
        active: user.active?
      }
    }
  end

  def report_search_result(report)
    {
      id: report.id,
      title: report.name,
      description: "Type: #{report.type} | Creator: #{report.creator&.name}",
      url: "/reports/#{report.id}",
      created_at: report.created_at,
      updated_at: report.updated_at,
      metadata: {
        type: report.type,
        creator: report.creator&.name,
        view_count: report.view_count
      }
    }
  end

  def comment_search_result(comment)
    {
      id: comment.id,
      title: "Comment by #{comment.author.name}",
      description: comment.content.truncate(100),
      url: "/responses/#{comment.response.id}#comment-#{comment.id}",
      created_at: comment.created_at,
      updated_at: comment.updated_at,
      metadata: {
        author: comment.author.name,
        response_shortcode: comment.response.shortcode,
        comment_type: comment.comment_type,
        resolved: comment.is_resolved?
      }
    }
  end

  def empty_results
    {
      items: [],
      total_count: 0,
      search_type: search_type || "all"
    }
  end
end
