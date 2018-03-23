# Handles conditional logic for a single question/answer pair in the response view based on conditions.
class ELMO.Views.ResponseConditionManager extends ELMO.Views.ApplicationView

  initialize: (options) ->
    @item = options.item
    @rootConditionGroup = @item.conditionGroup
    console.log("Initing for #{@item.fullDottedRank}: ", @rootConditionGroup)
    @inst = options.inst
    if @item.group
      @element = @groupElement(@item.id)
    else
      @element = @qingElement(@item.id, @inst)
    @readOnly = @element.is('.read-only')
    @result = true
    @root_checker = new ELMO.Views.ResponseConditionGroupChecker(
      el: @el,
      manager: this,
      group: @rootConditionGroup,
    inst: @inst)

    # The leaf node checkers have set their results when they were initialized, and now refresh
    # will call evaluate down the tree to read the leaf node checker results.
    @refresh()

  events:
    'submit': 'clearOnSubmitIfFalse'

  # Gathers results from all checkers and shows/hides the field based on them.
  refresh: ->
    newResult = @root_checker.evaluate()
    console.log("Manager refresh #{@rootConditionGroup.name} for #{@item.fullDottedRank}: #{newResult }")

    if newResult != @result
      @result = newResult
      @element[if @result then 'show' else 'hide']()
      @element.find('input.relevant').val(if @result then 'true' else 'false')

      # Simulate a change event on the control so that later conditions will be re-evaluated.
      @element.find('div.control').find('input, select, textarea').first().trigger('change')

  # When the form is submitted, clears the answer if the eval_result is false.
  clearOnSubmitIfFalse: ->
    unless @result
      @element.find("input[type='text'], textarea, select").val('')
      @element.find("input[type='checkbox']:checked, input[type='radio']:checked").each ->
        $(this).removeAttr('checked')

  # Finds the row in the response form for the given questioning ID within the instance
  # described by inst. If qingId doesn't exist within inst but some of its ancestors do, it will
  # do a partial match. This is useful for finding referred questioning rows
  # starting from the referring instance.
  qingElement: (qingId, inst) ->
    # We walk down through parent instances, constructing a
    # CSS selector for the appropriate instance at each step.
    # If there are no group parents, we just get an empty array.
    groupParents = @$(".form-field[data-qing-id=#{qingId}]").first().parents("div.qing-group")
    parentIds = groupParents.map(-> $(this).data("group-id").toString()).get()

    ignore = false
    parentSelectors = parentIds.map (id, depth) ->
      # We need to check that the instance descriptor we got matches the group hierarchy of the
      # requested node. If there is a mismatch as we walk down the tree, it means we should ignore the
      # rest of the given instance descriptor, which means we default to instance 1.
      ignore = true if !ignore && (!inst[depth] || inst[depth].id != id)
      instNum = if ignore then 1 else inst[depth].num
      "div.qing-group-instance[data-group-id=#{id}][data-inst-num=#{instNum}]"

    # Now we use the parent selectors to scope the actual form-field lookup.
    @$("#{parentSelectors.join(' ')} div.form-field[data-qing-id=#{qingId}]")

  # This function is used only to find the element that will be hidden or shown.
  # It gets the entire group container so that all instances of a repeat group are hidden or shown.
  groupElement: (groupId) ->
    @$("div.qing-group[data-group-id=#{groupId}]")


  results: ->
    @checkers.map (c) -> c.result
