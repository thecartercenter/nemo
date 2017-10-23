# Handles conditional logic for a single question/answer pair in the response view based on conditions.
class ELMO.Views.ResponseConditionManager extends ELMO.Views.ApplicationView

  initialize: (options) ->
    @item = options.item
    @conditions = @item.display_conditions
    @instNum = options.instNum
    @row = @formRow(@conditions[0].questioning_id, @instNum)
    @readOnly = @row.is('.read_only')
    @result = true

    @checkers = @conditions.map (c) =>
      new ELMO.Views.ResponseConditionChecker(el: @el, manager: this, condition: c, instNum: @instNum)

    @refresh()

  events:
    'submit': 'clearOnSubmitIfFalse'

  # Gathers results from all checkers and shows/hides the field based on them.
  refresh: ->
    newResult = @evaluate()

    if newResult != @result
      @result = newResult
      @row[if @result then 'show' else 'hide']()
      @row.find('input.relevant').val(if @result then 'true' else 'false')

      # Simulate a change event on the control so that later conditions will be re-evaluated.
      @row.find('div.control').find('input, select, textarea').first().trigger('change')

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

  results: ->
    @checkers.map (c) -> c.result

  formRow: (qingId, instNum) ->
    @$(".form_field[data-qing-id=#{qingId}][data-inst-num=#{instNum}]")
