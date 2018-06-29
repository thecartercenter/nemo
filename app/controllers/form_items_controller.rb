# frozen_string_literal: true

# FormItemsController
class FormItemsController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  after_action :check_rank_fail

  def update
    # Blank parent_id means parent is root
    params[:parent_id] = @form_item.form.root_id if params[:parent_id].blank?

    @form_item.move(FormItem.find(params[:parent_id]), params[:rank].to_i)
    render body: nil, status: 204
  end

  # Responds to ajax request with json containing data needed for condition form.
  def condition_form
    if params[:conditionable_id].present?
      @conditionable =
        if params[:conditionable_type] == "FormItem"
          FormItem.find(params[:conditionable_id])
        else
          SkipRule.find(params[:conditionable_id])
        end
    else
      # Create a dummy conditionable with the given form
      # so that the condition can look up the refable qings, etc.
      form = Form.find(params[:form_id])
      item = FormItem.new(form: form, mission: form.mission)
      @conditionable =
        if params[:conditionable_type] == "FormItem"
          item
        else
          SkipRule.new(source_item: item, mission: form.mission)
        end
    end

    authorize! :condition_form, @conditionable

    @condition = Condition.find_by(id: params[:condition_id])
    @condition ||= Condition.new(conditionable: @conditionable)

    @condition.ref_qing_id = params[:ref_qing_id]
    render json: ConditionViewSerializer.new(@condition), status: 200
  end
end
