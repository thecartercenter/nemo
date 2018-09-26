# Evaluates a single condition in the responses view.
class ELMO.Views.ResponseConditionChecker extends ELMO.Views.ApplicationView

  initialize: (options) ->
    @refresh = options.refresh
    @condition = options.condition

    @rqElement = @refQingElement(@$el, @condition.refQingId)
    @rqType = @rqElement.data('qtype-name')
    @result = true

    # These handlers must be set dynamically based on rqElement.
    @rqElement.find('div.control').find('input, select, textarea').on('change', => @checkAndTell())
    @rqElement.find('div.control input[type=text]').on('keyup', => @checkAndTell())
    @rqElement.find('div.control input[type=number]').on('keyup', => @checkAndTell())
    @textarea().on('tbwchange', => @checkAndTell()) if @rqType == 'long_text'

    # Set result to initial value on page load. Don't refresh because the manager calls refresh just
    # once on page load (if we 'tell' when each checker initializes, the manager would evaluate many times)
    @check()

  checkAndTell: ->
    @check()
    @refresh()

  evaluate: ->
    @result

  # Checks the result of the condition and sets the result value.
  check: ->
    unless @rqElement.is(':visible')
      @result = false
      return

    actual = @actual()
    expected = @expected()

    # For select_one questions, the actual will be an array of selected option_node_ids.
    # We should return true if the expected option_node_id is anywhere in that list.
    # So `eq` just becomes `inc` and `neq` becomes `ninc`.
    # We could label it this way in the condition form but it seems that would be confusing.
    op = @condition.op
    if @rqType == 'select_one'
      op = 'inc' if op == 'eq'
      op = 'ninc' if op == 'neq'

    @result = switch op
      when 'eq' then @testEquality(actual, expected)
      when 'lt' then actual < expected
      when 'gt' then actual > expected
      when 'leq' then actual <= expected
      when 'geq' then actual >= expected
      when 'neq' then @testInequality(actual, expected)
      when 'inc' then actual.indexOf(expected) != -1
      when 'ninc' then actual.indexOf(expected) == -1
      else false

  # We walk up the node tree until a descendant node contains the given qing ID.
  # Once found we return the first matching child.
  refQingElement: (srcElement, refQingId) ->
    parent = srcElement.parent().closest(".node")
    return null unless parent.length > 0
    children = parent.find(".node[data-qing-id=#{refQingId}]")
    if children.length > 0
      return children.first()
    else
      return @refQingElement(parent, refQingId)

  # Uses a special array comparison method if appropriate.
  testEquality: (a, b) ->
    if $.isArray(a) && $.isArray(b)
      a.equalsArray(b)
    else
      a == b

  # For inequality conditions, ignore nulls for relevance test
  # unless null is the value being checked by the condition
  # improves UX for appearing/disappearing questions.
  testInequality: (refValue, expected) ->
    if $.isArray(refValue) && $.isArray(expected)
      if refValue.equalsArray([]) && !expected.equalsArray([])
        false
      else
        !refValue.equalsArray(expected)
    else
      # If you aren't checking for "not null"
      if refValue == null && expected != null
        false
      else
        refValue != expected

  # Gets the actual answer for the referred question.
  actual: ->
    switch @rqType
      when 'long_text'
        # Strip wrapping <p> tag for comparison.
        @longTextContent().trim().replace(/(^<p>|<\/p>$)/ig, '')

      when 'integer', 'decimal', 'counter'
        parseFloat(@rqElement.find("div.control input[type=number]").val())

      when 'select_one'
        # Return all selected option_node_ids.
        @rqElement.find('select').map(->
          id = $(this).val()
          if id then id else null
        ).get()

      when 'select_multiple'
        # Use prev sibling call to get to rails gen'd hidden field that holds the id
        @rqElement.find('div.control input:checked').map(->
          # Given a checkbox, get the value of the associated option_node_id hidden field made by rails
          # this field is the nearest prior sibling input with name attribute ending in [option_node_id].
          $(this).closest('.choice').find("input[name$='[option_node_id]']").first().val()
        ).get()

      when 'datetime', 'date', 'time'
        (new ELMO.TimeFormField(@rqElement.find('div.control'))).extract_str()

      else
        @rqElement.find("div.control input[type='text']").val()

  # Gets the expected answer from the condition definition.
  expected: ->
    switch @rqType
      when 'integer', 'decimal', 'counter' then parseFloat(@condition.value)
      when 'select_one', 'select_multiple' then @condition.optionNodeId
      else @condition.value

  longTextContent: ->
    # Use wysiwyg editor if available, else use textarea value (usually just on startup).
    if @textarea().trumbowyg
      @textarea().trumbowyg('html')
    else
      @textarea().val()

  textarea: ->
    @rqElement.find('div.control textarea')
