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

    # Unlike the manager and the leaf node checkers, do NOT do anything to initialize here. The manager takes
    # care of that by calling refresh in its initialization.


  # Evaluates the children and returns the result.
  evaluate: ->
    if @conditionGroup.true_if == 'always'
      @applyNegation(true)
    else if @conditionGroup.true_if == 'all_met'
      @applyNegation(@childrenAllMet())
    else # any_met
      @applyNegation(@childrenAnyMet())

  childrenAllMet: ->
    results = @results()
    console.log("results for #{@conditionGroup.name}: #{results}")
    results.indexOf(false) == -1

  childrenAnyMet: ->
    @results().indexOf(true) != -1

  applyNegation: (bool) ->
    if @conditionGroup.negate
      !bool
    else
      bool

  results: ->
    @checkers.map (c) -> c.evaluate()

