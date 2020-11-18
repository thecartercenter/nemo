# frozen_string_literal: true

# Non-RESTful, JSON-only controller that provides data for the ConditionFormField component.
# Cuts across multiple models and builds a data structure needed by the view.
class ConditionFormDataController < ApplicationController
  # Returns data about a Condition including the relevant condition operators, referable questionings,
  # and its attributes.
  def base
    @conditionable = conditionable_from_provided_id || conditionable_from_form_id || build_conditionable
    authorize!(:condition_form, @conditionable)
    @condition = find_or_build_condition
    @condition.left_qing_id = params[:left_qing_id]
    render(json: ConditionalLogicForm::ConditionSerializer.render_as_json(@condition), status: :ok)
  end

  # Returns path information about:
  # - The OptionNode with the given node_id, or
  # - The root node of the OptionSet with the given option_set_id if node_id is not given or not found.
  def option_path
    option_node = OptionNode.find_by(id: params[:node_id]) # null if not found instead of throwing exception
    option_node ||= OptionSet.find(params[:option_set_id]).root_node
    authorize!(:show, option_node.option_set)
    render(json: ConditionalLogicForm::OptionPathSerializer.render_as_json(option_node))
  end

  private

  def conditionable_from_provided_id
    return nil if params[:conditionable_id].blank?
    case params[:conditionable_type]
    when "FormItem" then FormItem.find(params[:conditionable_id])
    when "Constraint" then Constraint.find(params[:conditionable_id])
    when "SkipRule" then SkipRule.find(params[:conditionable_id])
    else render(plain: "Invalid conditionable type")
    end
  end

  def conditionable_from_form_id
    return nil if params[:form_id].blank?
    # Create a dummy conditionable with the given form
    # so that the condition can look up the refable qings, etc.
    form = Form.find(params[:form_id])
    item = FormItem.new(form: form, mission: form.mission)
    if params[:conditionable_type] == "FormItem"
      item
    else
      SkipRule.new(source_item: item, mission: form.mission)
    end
  end

  def build_conditionable
    FormItem.new(mission: current_mission)
  end

  def find_or_build_condition
    Condition.find_by(id: params[:condition_id]) || Condition.new(conditionable: @conditionable)
  end
end
