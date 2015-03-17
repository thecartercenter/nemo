# methods required to setup a question for use in the new question form
module QuestionFormable
  extend ActiveSupport::Concern

  # initializes a questioning object with the given parameters. also adds a new question object.
  def init_qing(params = {})
    params[:ancestry] ||= Form.find(params[:form_id]).root_id

    # create a new questioning
    @questioning = Questioning.accessible_by(current_ability).new(params)
    @questioning.build_question if @questioning.question.nil?

    # override the associated question attributes with those mandated by the authorization system
    Question.accessible_by(current_ability).new.attributes.each_pair do |k,v|
      @questioning.question.send("#{k}=", v) unless v.nil?
    end

    # set the mission of the question and questioning to the current mission
    # to ensure proper permission handling
    @questioning.mission = @questioning.question.mission = current_mission
    @questioning
  end

  def setup_qing_form_support_objs
    setup_question_form_support_objs
    @condition = @questioning.condition || @questioning.build_condition

    # if the question instance var has not yet been set, get it from the questioning
    @question ||= @questioning.question
  end

  def setup_question_form_support_objs
    @question_types = QuestionType.all
    @option_sets = OptionSet.accessible_by(current_ability).default_order
  end
end