# Evaluates a single condition in the responses view.
class ELMO.Views.ResponseConditionGroupChecker extends ELMO.Views.ApplicationView

  initialize: (options) ->
    @manager = options.manager
    @condition_group = options.group
    @inst = options.inst
    @result = true
    @checkers = @condition_group.members.map (m) =>
      if m.type == "ConditionGroup"
        new ELMO.Views.ResponseConditionGroupChecker(el: @el, manager: @manager, group: m, inst: @inst)
      else
        new ELMO.Views.ResponseConditionChecker(el: @el, manager: @manager, condition: m, inst: @inst)
    @eval()


  # Evaluates the children and sets the result.
  eval: ->
    if @condition_group.true_if == 'all_met'
      @results().indexOf(false) == -1
    else # any_met
      @results().indexOf(true) != -1

  results: ->
    @checkers.map (c) -> c.result

