# Handles conditional logic for a single question/answer pair in the response view based on conditions.
class ELMO.Views.HierarchicalResponseConditionManager extends ELMO.Views.ApplicationView

  initialize: (options) ->
    @item = options.item
    @rootConditionGroup = @item.conditionGroup
    @readOnly = @$el.is('.read-only')
    @result = true
    @rootChecker = new ELMO.Views.HierarchicalResponseConditionGroupChecker(
      el: @el,
      manager: this,
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
      @$el.find('input.relevant').val(if @result then 'true' else 'false')

      # Simulate a change event on the control so that later conditions will be re-evaluated.
      @$el.find('div.control').find('input, select, textarea').first().trigger('change')

  # When the form is submitted, clears the answer if the eval_result is false.
  clearOnSubmitIfFalse: ->
    unless @result
      @$el.find("input[type='text'], textarea, select").val('')
      @$el.find("input[type='checkbox']:checked, input[type='radio']:checked").each ->
        $(this).removeAttr('checked')

  # Finds the row in the response form for the given questioning ID within the instance
  # described by inst. If qingId doesn't exist within inst but some of its ancestors do, it will
  # do a partial match. This is useful for finding referred questioning rows
  # starting from the referring instance.
  qingElement: (qingId) ->
    find = (el) ->
      parent = el.parent().closest(".node")
      return null unless parent.length > 0
      children = parent.find(".node[data-qing-id=#{qingId}]")
      if children.length > 0
        return children.first()
      else
        return find(parent)

    find(@$el)

  results: ->
    @checkers.map (c) -> c.result
