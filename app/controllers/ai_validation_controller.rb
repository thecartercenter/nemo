# frozen_string_literal: true

class AiValidationController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mission

  def index
    authorize!(:view, :ai_validation)
    
    @rules = AiValidationRule.where(mission: @mission)
                             .includes(:user, :ai_validation_results)
                             .order(created_at: :desc)
                             .paginate(page: params[:page], per_page: 20)
  end

  def show
    @rule = AiValidationRule.find(params[:id])
    authorize!(:view, @rule)
    
    @results = @rule.ai_validation_results
                    .includes(:response)
                    .order(created_at: :desc)
                    .paginate(page: params[:page], per_page: 20)
    
    @stats = {
      total_validations: @results.total_entries,
      passed: @results.passed.count,
      failed: @results.failed.count,
      pass_rate: calculate_pass_rate(@results)
    }
  end

  def new
    authorize!(:create, :ai_validation_rule)
    
    @rule = AiValidationRule.new(mission: @mission, user: current_user)
    @rule_types = AiValidationRule::RULE_TYPES
    @ai_models = AiValidationRule::AI_MODELS
  end

  def create
    authorize!(:create, :ai_validation_rule)
    
    @rule = AiValidationRule.new(rule_params.merge(mission: @mission, user: current_user))
    
    if @rule.save
      redirect_to ai_validation_rule_path(@rule), notice: 'AI validation rule was successfully created.'
    else
      @rule_types = AiValidationRule::RULE_TYPES
      @ai_models = AiValidationRule::AI_MODELS
      render :new
    end
  end

  def edit
    @rule = AiValidationRule.find(params[:id])
    authorize!(:update, @rule)
    
    @rule_types = AiValidationRule::RULE_TYPES
    @ai_models = AiValidationRule::AI_MODELS
  end

  def update
    @rule = AiValidationRule.find(params[:id])
    authorize!(:update, @rule)
    
    if @rule.update(rule_params)
      redirect_to ai_validation_rule_path(@rule), notice: 'AI validation rule was successfully updated.'
    else
      @rule_types = AiValidationRule::RULE_TYPES
      @ai_models = AiValidationRule::AI_MODELS
      render :edit
    end
  end

  def destroy
    @rule = AiValidationRule.find(params[:id])
    authorize!(:destroy, @rule)
    
    @rule.destroy
    redirect_to ai_validation_rules_path, notice: 'AI validation rule was successfully deleted.'
  end

  def toggle_active
    @rule = AiValidationRule.find(params[:id])
    authorize!(:update, @rule)
    
    @rule.update!(active: !@rule.active)
    
    render json: { 
      success: true, 
      active: @rule.active?,
      message: @rule.active? ? 'Rule activated' : 'Rule deactivated'
    }
  end

  def test_rule
    @rule = AiValidationRule.find(params[:id])
    authorize!(:update, @rule)
    
    response = Response.find(params[:response_id])
    result = @rule.validate_response(response)
    
    render json: {
      success: true,
      result: {
        confidence: result.confidence_score,
        is_valid: result.is_valid?,
        passed: result.passed?,
        issues: result.issues,
        suggestions: result.suggestions,
        explanation: result.explanation
      }
    }
  end

  def validate_response
    response = Response.find(params[:response_id])
    authorize!(:view, response)
    
    results = AiValidationService.validate_response(response)
    
    render json: {
      success: true,
      results: results.map do |result|
        {
          rule_name: result.ai_validation_rule.name,
          rule_type: result.validation_type,
          confidence: result.confidence_score,
          passed: result.passed?,
          issues: result.issues,
          suggestions: result.suggestions,
          explanation: result.explanation
        }
      end
    }
  end

  def validate_batch
    authorize!(:manage, :ai_validation)
    
    form_ids = params[:form_ids] || []
    date_from = params[:date_from]
    date_to = params[:date_to]
    
    responses = Response.where(mission: @mission)
    responses = responses.where(form_id: form_ids) if form_ids.any?
    responses = responses.where('created_at >= ?', Date.parse(date_from).beginning_of_day) if date_from.present?
    responses = responses.where('created_at <= ?', Date.parse(date_to).end_of_day) if date_to.present?
    
    results = AiValidationService.validate_batch(responses)
    
    render json: {
      success: true,
      message: "Validated #{results.count} responses",
      results_count: results.count,
      passed_count: results.count { |r| r.passed? },
      failed_count: results.count { |r| !r.passed? }
    }
  end

  def report
    authorize!(:view, :ai_validation)
    
    date_range = if params[:date_from].present? && params[:date_to].present?
                   Date.parse(params[:date_from]).beginning_of_day..Date.parse(params[:date_to]).end_of_day
                 end
    
    @report = AiValidationService.generate_validation_report(@mission, date_range)
    
    respond_to do |format|
      format.html
      format.json { render json: @report }
    end
  end

  def suggestions
    authorize!(:view, :ai_validation)
    
    suggestions = AiValidationService.suggest_validation_rules(@mission)
    
    render json: {
      success: true,
      suggestions: suggestions
    }
  end

  def create_from_suggestion
    authorize!(:create, :ai_validation_rule)
    
    suggestion = params[:suggestion]
    
    @rule = AiValidationRule.create!(
      name: suggestion[:name],
      description: suggestion[:description],
      rule_type: suggestion[:type],
      config: {},
      ai_model: 'gpt-3.5-turbo',
      threshold: 0.8,
      mission: @mission,
      user: current_user
    )
    
    render json: {
      success: true,
      rule: {
        id: @rule.id,
        name: @rule.name,
        description: @rule.description,
        rule_type: @rule.rule_type
      }
    }
  end

  private

  def set_mission
    @mission = current_mission
  end

  def rule_params
    params.require(:ai_validation_rule).permit(
      :name, :description, :rule_type, :ai_model, :threshold, :active,
      config: [:max_length, :min_score] # Only permit expected config keys
    )
  end

  def calculate_pass_rate(results)
    return 0 if results.empty?
    
    passed_count = results.count { |r| r.passed? }
    (passed_count.to_f / results.count * 100).round(2)
  end
end