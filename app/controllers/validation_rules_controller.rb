# frozen_string_literal: true

class ValidationRulesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mission
  before_action :set_validation_rule, only: [:show, :edit, :update, :destroy, :toggle]

  def index
    authorize!(:view, :validation_rules)
    
    @validation_rules = ValidationRule.where(mission: @mission)
                                    .includes(:form, :question)
                                    .order(:name)

    # Apply filters
    @validation_rules = @validation_rules.where(rule_type: params[:rule_type]) if params[:rule_type].present?
    @validation_rules = @validation_rules.where(form_id: params[:form_id]) if params[:form_id].present?
    @validation_rules = @validation_rules.where(is_active: params[:is_active]) if params[:is_active].present?
    @validation_rules = @validation_rules.where("name ILIKE ?", "%#{params[:search]}%") if params[:search].present?

    @validation_rules = @validation_rules.paginate(page: params[:page], per_page: 20)
    
    @forms = Form.accessible_by(current_ability).where(mission: @mission)
    @rule_types = ValidationRule::RULE_TYPES
  end

  def show
    authorize!(:view, :validation_rules)
  end

  def new
    authorize!(:create, :validation_rules)
    @validation_rule = ValidationRule.new(mission: @mission)
    @forms = Form.accessible_by(current_ability).where(mission: @mission)
    @questions = []
  end

  def create
    authorize!(:create, :validation_rules)
    
    @validation_rule = ValidationRule.new(validation_rule_params.merge(mission: @mission))
    
    if @validation_rule.save
      redirect_to validation_rules_path, notice: 'Validation rule created successfully.'
    else
      @forms = Form.accessible_by(current_ability).where(mission: @mission)
      @questions = @validation_rule.form&.questions || []
      render :new
    end
  end

  def edit
    authorize!(:update, @validation_rule)
    @forms = Form.accessible_by(current_ability).where(mission: @mission)
    @questions = @validation_rule.form&.questions || []
  end

  def update
    authorize!(:update, @validation_rule)
    
    if @validation_rule.update(validation_rule_params)
      redirect_to validation_rules_path, notice: 'Validation rule updated successfully.'
    else
      @forms = Form.accessible_by(current_ability).where(mission: @mission)
      @questions = @validation_rule.form&.questions || []
      render :edit
    end
  end

  def destroy
    authorize!(:destroy, @validation_rule)
    
    @validation_rule.destroy
    redirect_to validation_rules_path, notice: 'Validation rule deleted successfully.'
  end

  def toggle
    authorize!(:update, @validation_rule)
    
    @validation_rule.update!(is_active: !@validation_rule.is_active?)
    
    redirect_to validation_rules_path, notice: "Validation rule #{@validation_rule.is_active? ? 'activated' : 'deactivated'} successfully."
  end

  def test
    authorize!(:view, :validation_rules)
    
    @response = Response.accessible_by(current_ability).find(params[:response_id])
    @validation_errors = ValidationRule.validate_response(@response)
    
    render json: {
      response_id: @response.id,
      errors: @validation_errors
    }
  end

  def get_questions
    authorize!(:view, :validation_rules)
    
    form = Form.accessible_by(current_ability).find(params[:form_id])
    questions = form.questions.map do |question|
      {
        id: question.id,
        code: question.code,
        name: question.name,
        type: question.qtype_name
      }
    end
    
    render json: { questions: questions }
  end

  private

  def set_mission
    @mission = current_mission
  end

  def set_validation_rule
    @validation_rule = ValidationRule.find(params[:id])
  end

  def validation_rule_params
    params.require(:validation_rule).permit(
      :name, :description, :rule_type, :message, :is_active,
      :form_id, :question_id,
      # Explicitly permitted keys in 'conditions'
      conditions: [:operator, :field, :value] # Update these keys as appropriate to your application
    )
  end
end