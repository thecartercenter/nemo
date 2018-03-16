# Evaluates a single condition in the responses view.
class ELMO.Views.ResponseConditionGroupChecker extends ELMO.Views.ApplicationView

  initialize: (options) ->
    @manager = options.manager
    @conditionGroup = options.group
    @inst = options.inst
    @checkers = @conditionGroup.members.map (m) =>
      if m.type == "ConditionGroup"
        new ELMO.Views.ResponseConditionGroupChecker(el: @el, manager: @manager, group: m, inst: @inst)
      else
        new ELMO.Views.ResponseConditionChecker(el: @el, manager: @manager, condition: m, inst: @inst)
    @evaluate()


  # Evaluates the children and sets the result.
  evaluate: ->
    #handle negation [write spec first]
    #handle true_if == 'always' [write spec first]
    if @conditionGroup.true_if == 'all_met'
      @results().indexOf(false) == -1
    else # any_met
      @results().indexOf(true) != -1

  results: ->
    @checkers.map (c) -> c.evaluate()

