# Newer view to manage Question/Questioning form.
class ELMO.Views.QuestionFormView extends ELMO.Views.ApplicationView
  initialize: (options) ->
    @prefillableTypes = options.prefillableTypes # Will be null for Question form
    @$('select[id$="_qtype_name"]').trigger('change')

  events:
    'change select[id$="_qtype_name"]': 'typeChanged'

  typeChanged: (e) ->
    newType = @$(e.target).val()
    @toggleAutoIncrement(newType)
    @togglePrefillPattern(newType)

  toggleAutoIncrement: (type) ->
    @$('.question_auto_increment')[if type == 'counter' then 'show' else 'hide']()

  togglePrefillPattern: (type) ->
    if @prefillableTypes
      if @prefillableTypes.indexOf(type) != -1
        @$('.questioning_prefill_pattern').show()
      else
        @$('.questioning_prefill_pattern').hide()
