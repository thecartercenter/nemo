class QuestioningsController < ApplicationController
  # this Concern includes routines for building question/ing forms
  include QuestionFormable
  include Parameters

  # init the questioning object in a special way before load_resource
  before_filter :init_qing_with_form_id, :only => [:create]

  # authorization via cancan
  load_and_authorize_resource

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
    strip_condition_params_if_empty(permitted_params)

    # Convert tag string from TokenInput to array
    if (tag_ids = permitted_params[:question_attributes].try(:[], :tag_ids))
      permitted_params[:question_attributes][:tag_ids] = tag_ids.split(',')
    end

    # assign attribs and validate now so that normalization runs before authorizing and saving
    @questioning.assign_attributes(permitted_params)
    @questioning.valid?

    # authorize special abilities
    %w(required hidden condition).each do |f|
      authorize!(:"update_#{f}", @questioning) if @questioning.send("#{f}_changed?")
    end
    authorize!(:update_core, @questioning.question) if @questioning.question.core_changed?

    if @questioning.save
      set_success_and_redirect(@questioning.question, :to => edit_form_path(@questioning.form))
    else
      prepare_and_render_form
    end
  end

  # Only called via AJAX
  def destroy
    @questioning.destroy
    render nothing: true, status: 204
  end

  # Re-renders the fields in the condition form when requested by ajax.
  def condition_form
    if params[:questioning_id].present?
      @questioning = Questioning.find(params[:questioning_id])
    else
      # Create a dummy questioning so that the condition can look up the refable qings, etc.
      @questioning = init_qing(form_id: params[:form_id])
    end

    # Create a dummy condition with the given ref qing.
    @condition = @questioning.build_condition(ref_qing_id: params[:ref_qing_id])
    render(partial: 'conditions/form_fields')
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
      strip_condition_params_if_empty(permitted_params)
      init_qing(permitted_params)
    end

    # strips out condition fields if they're blank and questioning has no existing condition
    # this prevents an empty condition from getting initialized and then deleted again
    # this is not set as a filter due to timing issues
    def strip_condition_params_if_empty(permitted_params)
      if permitted_params[:condition_attributes] &&
        permitted_params[:condition_attributes][:ref_qing_id].blank? &&
        (!@questioning || !@questioning.condition)
        permitted_params.delete(:condition_attributes)
      end
    end

    def questioning_params
      params.require(:questioning).permit(:form_id, :allow_incomplete, :access_level, :hidden,
        :required, :prefill_pattern,
        { condition_attributes: [:id, :ref_qing_id, :op, :value, option_node_ids: []] },
        { question_attributes: whitelisted_question_params(params[:questioning][:question_attributes]) })
    end
end
