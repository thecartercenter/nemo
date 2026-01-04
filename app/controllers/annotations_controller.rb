# frozen_string_literal: true

class AnnotationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_response
  before_action :set_annotation, only: %i[show edit update destroy]

  def index
    authorize!(:view, @response)

    @annotations = @response.annotations.includes(:author, :answer)
      .recent
      .paginate(page: params[:page], per_page: 20)

    @annotation_types = Annotation::ANNOTATION_TYPES
  end

  def show
    authorize!(:view, @response)
  end

  def new
    authorize!(:create, :annotation)
    @annotation = @response.annotations.build(author: current_user)
    @annotation_types = Annotation::ANNOTATION_TYPES
  end

  def edit
    authorize!(:update, @annotation)
  end

  def create
    authorize!(:create, :annotation)

    @annotation = @response.annotations.build(annotation_params.merge(author: current_user))

    if @annotation.save
      respond_to do |format|
        format.html { redirect_to(response_path(@response), notice: "Annotation added successfully.") }
        format.json { render(json: @annotation, status: :created) }
      end
    else
      @annotation_types = Annotation::ANNOTATION_TYPES
      respond_to do |format|
        format.html { render(:new) }
        format.json { render(json: {errors: @annotation.errors}, status: :unprocessable_entity) }
      end
    end
  end

  def update
    authorize!(:update, @annotation)

    if @annotation.update(annotation_params)
      respond_to do |format|
        format.html { redirect_to(response_path(@response), notice: "Annotation updated successfully.") }
        format.json { render(json: @annotation) }
      end
    else
      respond_to do |format|
        format.html { render(:edit) }
        format.json { render(json: {errors: @annotation.errors}, status: :unprocessable_entity) }
      end
    end
  end

  def destroy
    authorize!(:destroy, @annotation)

    @annotation.destroy
    respond_to do |format|
      format.html { redirect_to(response_path(@response), notice: "Annotation deleted successfully.") }
      format.json { head(:no_content) }
    end
  end

  private

  def set_response
    @response = Response.accessible_by(current_ability).find(params[:response_id])
  end

  def set_annotation
    @annotation = @response.annotations.find(params[:id])
  end

  def annotation_params
    params.require(:annotation).permit(
      :content, :annotation_type, :is_public, :answer_id,
      position: %i[x y width height]
    )
  end
end
