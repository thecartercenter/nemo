# Newer view to manage Question/Questioning form.
class ELMO.Views.QuestionFormView extends ELMO.Views.ApplicationView
  initialize: (options) ->
    @prefillableTypes = options.prefillableTypes # Will be null for Question form
    @toggleFields()

  events:
    'change select[id$="_qtype_name"]': 'typeChanged'

  typeChanged: (e) ->
    @toggleFields()

  toggleFields: ->
    type = @fieldValue('qtype_name')
    @toggleAutoIncrement(type)
    @togglePrefillPattern(type)

  toggleAutoIncrement: (type) ->
    @$('.question_auto_increment')[if type == 'counter' then 'show' else 'hide']()

  togglePrefillPattern: (type) ->
    if @prefillableTypes
      if @prefillableTypes.indexOf(type) != -1
        @$('.questioning_prefill_pattern').show()
      else
        @$('.questioning_prefill_pattern').hide()

  # Gets form field value, or static value if field is read-only
  fieldValue: (attrib) ->
    div = @$(".question_fields .form_field[data-field-name=#{attrib}] .control")
    if div.is('.read_only')
      wrapper = div.find('.ro-val')
      wrapper.data('val') || wrapper.text()
    else
      div.find('input, select, textarea').val()
