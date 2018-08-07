class QuestioningsController < ApplicationController
  # this Concern includes routines for building question/ing forms
  include QuestionFormable
  include Parameters

  # init the questioning object in a special way before load_resource
  before_action :init_qing_with_form_id, :only => [:create]
  after_action :check_rank_fail

  # authorization via cancan
  load_and_authorize_resource except: :condition_form

  def edit
    prepare_and_render_form
  end

  def show
    prepare_and_render_form
  end

  def create
    @questioning.question.is_standard = true if current_mode == 'admin'

    permitted_params = questioning_params

    # Convert tag string from TokenInput to array
    @questioning.question.tag_ids = permitted_params[:question_attributes][:tag_ids].split(',')

    if @questioning.save
      set_success_and_redirect(@questioning.question, :to => edit_form_path(@questioning.form))
    else
      flash.now[:error] = I18n.t("activerecord.errors.models.question.general")
      prepare_and_render_form
    end
  end

  def update
    permitted_params = questioning_params

    # Convert tag string from TokenInput to array
    if (tag_ids = permitted_params[:question_attributes].try(:[], :tag_ids))
      permitted_params[:question_attributes][:tag_ids] = tag_ids.split(',')
    end

    # assign attribs and validate now so that normalization runs before authorizing and saving
    @questioning.assign_attributes(permitted_params)
    @questioning.valid?

    authorize!(:update_core, @questioning) if @questioning.core_changed?
    authorize!(:update_core, @questioning.question) if @questioning.question.core_changed?

    if @questioning.save
      set_success_and_redirect(@questioning.question, :to => edit_form_path(@questioning.form))
    else
      flash.now[:error] = I18n.t("activerecord.errors.models.question.general")
      prepare_and_render_form
    end
  end

  # Only called via AJAX
  def destroy
    @questioning.destroy
    head(204)
  end

  private

  # prepares objects for and renders the form template
  def prepare_and_render_form
    # this method lives in the QuestionFormable concern
    setup_qing_form_support_objs
    render(:form)
  end

  # inits the questioning using the proper method in QuestionFormable
  def init_qing_with_form_id
    permitted_params = questioning_params
    authorize! :create, Questioning
    init_qing(permitted_params)
  end

  def questioning_params
    condition_params = [:id, :ref_qing_id, :op, :value, :_destroy, option_node_ids: []]
    params.require(:questioning).permit(:form_id, :allow_incomplete, :access_level, :hidden,
      :required, :default, :read_only, :display_if,
      {display_conditions_attributes: condition_params},
      {skip_rules_attributes: [:id, :destination, :dest_item_id, :skip_if, :_destroy,
        conditions_attributes: condition_params]},
      {question_attributes: whitelisted_question_params(params[:questioning][:question_attributes])})
  end
end
