# Handles conditional logic for a single question/answer pair in the response view based on conditions.
class ELMO.Views.HierarchicalResponseConditionManager extends ELMO.Views.ApplicationView

  initialize: (options) ->
    @item = options.item
    @rootConditionGroup = @item.conditionGroup
    @result = true
    @rootChecker = new ELMO.Views.HierarchicalResponseConditionGroupChecker(
      el: @el,
      refresh: @refresh.bind(this),
      group: @rootConditionGroup
    )

    # The leaf node checkers have set their results when they were initialized, and now refresh
    # will call evaluate down the tree to read the leaf node checker results.
    @refresh()

  events:
    'submit': 'clearOnSubmitIfFalse'

  # Gathers results from all checkers and shows/hides the field based on them.
  refresh: ->
    newResult = @rootChecker.evaluate()

    if newResult != @result
      @result = newResult
      @$el.toggle(@result)
      @$el.find('input.relevant').first().val(if @result then 'true' else 'false')

      # Simulate a change event on the control so that later conditions will be re-evaluated.
      @$el.find('div.control').find('input, select, textarea').first().trigger('change')

  # When the form is submitted, clears the answer if the eval_result is false.
  clearOnSubmitIfFalse: ->
    unless @result
      @$el.find("input[type='text'], textarea, select").val('')
      @$el.find("input[type='checkbox']:checked, input[type='radio']:checked").each ->
        $(this).removeAttr('checked')

  results: ->
    @checkers.map (c) -> c.result
