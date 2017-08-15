# Newer view to manage Question/Questioning form.
class ELMO.Views.QuestionFormView extends ELMO.Views.ApplicationView
  initialize: (options) ->
    @prefillableTypes = options.prefillableTypes # Will be null for Question form
    @toggleFields()
    @toggleRequired(@$('#questioning_read_only')[0].checked)
    @toggleReadOnly(@$('#questioning_prefill_pattern')[0].value)

  events:
    'change select[id$="_qtype_name"]': 'typeChanged'
    'click #questioning_read_only': 'readOnlyStatusChanged'
    'keyup #questioning_prefill_pattern' : 'prefillPatternChanged'

  typeChanged: (e) ->
    @toggleFields()

  prefillPatternChanged: (e) ->
    console.log("prefill pattern changed")
    prefill_value = e.target.value
    @toggleReadOnly(prefill_value)

  toggleReadOnly: (prefill_value) ->
    console.log('prefill value: ' + prefill_value)
    @$('.questioning_read_only')[if prefill_value == '' then 'hide' else 'show']()

  readOnlyStatusChanged: (e) ->
    @toggleRequired(e.target.checked)

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
        @$('.questioning_read_only').show()
      else
        @$('.questioning_prefill_pattern').hide()
        @$('.questioning_read_only').hide()

  toggleRequired: (readOnly) ->
    console.log("toggle Required")
    console.log("readonly is: " + readOnly)
    @$('.questioning_required')[if readOnly then 'hide' else 'show']()

  # Gets form field value, or static value if field is read-only
  fieldValue: (attrib) ->
    div = @$(".question_fields .form_field[data-field-name=#{attrib}] .control")
    if div.is('.read_only')
      wrapper = div.find('.ro-val')
      wrapper.data('val') || wrapper.text()
    else
      div.find('input, select, textarea').val()
