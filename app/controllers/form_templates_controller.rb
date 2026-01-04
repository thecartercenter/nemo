# frozen_string_literal: true

class FormTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mission
  before_action :set_form_template, only: %i[show edit update destroy use]

  def index
    authorize!(:view, :form_templates)

    @templates = FormTemplate.accessible_by(current_ability)
      .includes(:creator)
      .recent

    # Apply filters
    @templates = @templates.by_category(params[:category]) if params[:category].present?
    @templates = @templates.search(params[:search]) if params[:search].present?
    @templates = @templates.public_templates if params[:public_only] == "true"
    @templates = @templates.popular if params[:sort] == "popular"

    @templates = @templates.paginate(page: params[:page], per_page: 20)

    @categories = FormTemplate::CATEGORIES
    @public_templates_count = FormTemplate.public_templates.count
  end

  def show
    authorize!(:view, :form_templates)
    @preview_data = @form_template.preview_data
  end

  def new
    authorize!(:create, :form_templates)
    @form_template = FormTemplate.new
    @forms = Form.accessible_by(current_ability).where(mission: @mission)
  end

  def edit
    authorize!(:update, @form_template)
  end

  def create
    authorize!(:create, :form_templates)

    @form_template = FormTemplate.new(form_template_params.merge(creator: current_user, mission: @mission))

    if @form_template.save
      redirect_to(form_template_path(@form_template), notice: "Form template created successfully.")
    else
      @forms = Form.accessible_by(current_ability).where(mission: @mission)
      render(:new)
    end
  end

  def update
    authorize!(:update, @form_template)

    if @form_template.update(form_template_params)
      redirect_to(form_template_path(@form_template), notice: "Form template updated successfully.")
    else
      render(:edit)
    end
  end

  def destroy
    authorize!(:destroy, @form_template)

    @form_template.destroy
    redirect_to(form_templates_path, notice: "Form template deleted successfully.")
  end

  def use
    authorize!(:use, @form_template)

    unless @form_template.can_be_used_by?(current_user)
      redirect_to(form_templates_path, alert: "You do not have permission to use this template.")
      return
    end

    @form_name = params[:form_name] || @form_template.name
  end

  def create_from_template
    @form_template = FormTemplate.find(params[:id])
    authorize!(:use, @form_template)

    unless @form_template.can_be_used_by?(current_user)
      redirect_to(form_templates_path, alert: "You do not have permission to use this template.")
      return
    end

    begin
      form = @form_template.create_form_from_template(@mission, current_user, form_name: params[:form_name])

      # Log the template usage
      AuditLog.log_action(
        current_user,
        :create,
        :Form,
        resource_id: form.id,
        metadata: {template_id: @form_template.id, template_name: @form_template.name}
      )

      redirect_to(form_path(form),
        notice: "Form '#{form.name}' created successfully from template '#{@form_template.name}'.")
    rescue StandardError => e
      redirect_to(use_form_template_path(@form_template), alert: "Failed to create form from template: #{e.message}")
    end
  end

  def create_from_form
    authorize!(:create, :form_templates)

    form = Form.accessible_by(current_ability).find(params[:form_id])

    @form_template = FormTemplate.create_from_form(
      form,
      current_user,
      name: params[:name],
      description: params[:description],
      category: params[:category],
      tags: params[:tags] || [],
      is_public: params[:is_public] == "true"
    )

    redirect_to(form_template_path(@form_template), notice: "Form template created successfully from form.")
  end

  private

  def set_mission
    @mission = current_mission
  end

  def set_form_template
    @form_template = FormTemplate.find(params[:id])
  end

  def form_template_params
    params.require(:form_template).permit(
      :name, :description, :category, :is_public,
      tags: []
    )
  end
end
