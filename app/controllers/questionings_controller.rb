# frozen_string_literal: true

class QuestioningsController < ApplicationController
  include ConditionFormable
  include QuestionFormable
  include Parameters

  # init the questioning object in a special way before load_resource
  before_action :init_qing_with_form_id, only: [:create]

  # authorization via cancan
  load_and_authorize_resource except: :condition_form

  def edit
    prepare_and_render_form
  end

  def show
    prepare_and_render_form
  end

  def create
    permitted_params = questioning_params

    # Convert tag string from TokenInput to array
    @questioning.question.tag_ids = permitted_params[:question_attributes][:tag_ids].split(",")

    create_or_update
  end

  def update
    permitted_params = questioning_params

    # Convert tag string from TokenInput to array
    if (tag_ids = permitted_params[:question_attributes].try(:[], :tag_ids))
      permitted_params[:question_attributes][:tag_ids] = tag_ids.split(",")
    end

    # Force a Question update, otherwise the attachment won't save if nothing else was modified.
    if permitted_params[:question_attributes][:media_prompt].present?
      permitted_params[:question_attributes][:updated_at] = Time.current
    end

    # assign attribs and validate now so that normalization runs before authorizing and saving
    @questioning.assign_attributes(permitted_params)
    @questioning.valid?

    authorize!(:update_core, @questioning) if @questioning.core_changed?
    authorize!(:update_core, @questioning.question) if @questioning.question.core_changed?

    create_or_update
  end

  # Only called via AJAX
  def destroy
    @questioning.destroy
    head(204)
  end

  private

  def create_or_update
    if @questioning.save
      set_success_and_redirect(@questioning.question, to: edit_form_path(@questioning.form))
    else
      flash.now[:error] = I18n.t("activerecord.errors.models.question.general")
      prepare_and_render_form
    end
  end

  # prepares objects for and renders the form template
  def prepare_and_render_form
    # this method lives in the QuestionFormable concern
    setup_qing_form_support_objs
    render(:form)
  end

  # inits the questioning using the proper method in QuestionFormable
  def init_qing_with_form_id
    permitted_params = questioning_params
    authorize!(:create, Questioning)
    init_qing(permitted_params)
  end

  def questioning_params
    params.require(:questioning).permit(:form_id, :allow_incomplete, :access_level, :hidden, :disabled,
      :required, :default, :read_only, :display_if, :all_levels_required, :preload_last_saved,
      {display_conditions_attributes: condition_params},
      {skip_rules_attributes: [:id, :destination, :dest_item_id, :skip_if, :_destroy,
                               {conditions_attributes: condition_params}]},
      {constraints_attributes: [
        :id, :accept_if, :_destroy,
        {conditions_attributes: condition_params,
         rejection_msg_translations: configatron.preferred_locales}
      ]},
      question_attributes: whitelisted_question_params(params[:questioning][:question_attributes]))
  end
end
