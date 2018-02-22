# Handles conditional logic for a single question/answer pair in the response view based on conditions.
class ELMO.Views.GroupConditionManager extends ELMO.Views.ApplicationView

  initialize: (options) ->
    console.warn "initialize group condition manager"
    @item = options.item
    @conditions = @item.display_conditions
    @inst = options.inst
    console.warn(@item)
    @element = @findGroupElement(@item.id, @inst)
    @readOnly = false# @row.is('.read-only')
    @result = true

    @checkers = @conditions.map (c) =>
      new ELMO.Views.ResponseConditionChecker(el: @el, manager: this, condition: c, inst: @inst)

    @refresh()

  events:
    'submit': 'clearOnSubmitIfFalse'

  # Gathers results from all checkers and shows/hides the field based on them.
  refresh: ->
    console.warn "refresh"
    newResult = @evaluate()

    if newResult != @result
      @result = newResult
      console.log(@element)
      @element[if @result then 'show' else 'hide']()
      #TODO traverse children for this
      #@row.find('input.relevant').val(if @result then 'true' else 'false')

      #TODO and traverse children and change each child
      # Simulate a change event on the control so that later conditions will be re-evaluated.
      #@row.find('div.control').find('input, select, textarea').first().trigger('change')

  evaluate: ->
    # By now we know that display_if must be all_met or any_met.
    if @item.display_if == 'all_met'
      @results().indexOf(false) == -1
    else # any_met
      @results().indexOf(true) != -1

  # When the form is submitted, clears the answer if the eval_result is false.
  clearOnSubmitIfFalse: ->
    unless @result
      @row.find("input[type='text'], textarea, select").val('')
      @row.find("input[type='checkbox']:checked, input[type='radio']:checked").each ->
        $(this).removeAttr('checked')

  # Finds the row in the response form for the given questioning ID within the instance
  # described by inst. If qingId doesn't exist within inst but some of its ancestors do, it will
  # do a partial match. This is useful for finding referred questioning rows
  # starting from the referring instance.
  formRow: (qingId, inst) ->
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

  # Finds the row in the response form for the given questioning ID within the instance
  # described by inst. If qingId doesn't exist within inst but some of its ancestors do, it will
  # do a partial match. This is useful for finding referred questioning rows
  # starting from the referring instance.
  findGroupElement: (groupId, inst) ->
    console.log("findGroupElement")
    console.log(groupId)
    ignore = false; #true if !ignore && (!inst[depth] || inst[depth].id != id)
    instNum = 1 #if ignore then 1 else inst[depth].num
    @$("div.qing-group-instance[data-group-id=#{groupId}][data-inst-num=#{instNum}]")
    # # We walk down through parent instances, constructing a
    # # CSS selector for the appropriate instance at each step.
    # # If there are no group parents, we just get an empty array.
    # groupParents = @$(".form-field[data-qing-id=#{qingId}]").first().parents("div.qing-group")
    # parentIds = groupParents.map(-> $(this).data("group-id").toString()).get()
    #
    # ignore = false
    # parentSelectors = parentIds.map (id, depth) ->
    #   # We need to check that the instance descriptor we got matches the group hierarchy of the
    #   # requested node. If there is a mismatch as we walk down the tree, it means we should ignore the
    #   # rest of the given instance descriptor, which means we default to instance 1.
    #   ignore = true if !ignore && (!inst[depth] || inst[depth].id != id)
    #   instNum = if ignore then 1 else inst[depth].num
    #
    #
    # # Now we use the parent selectors to scope the actual form-field lookup.
    # @$("#{parentSelectors.join(' ')} div.form-field[data-qing-id=#{qingId}]")

  results: ->
    @checkers.map (c) -> c.result