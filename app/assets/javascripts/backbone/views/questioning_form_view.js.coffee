# Newer view to manage Questioning form.
class ELMO.Views.QuestioningFormView extends ELMO.Views.QuestionFormView
  initialize: (options) ->
    @prefillableTypes = options.prefillableTypes
    @toggleFields()
    @toggleReadOnly()

  events:
    'change select[id$="_qtype_name"]': 'typeChanged'
    'click #questioning_read_only': 'toggleRequired'
    'keyup #questioning_prefill_pattern' : 'toggleReadOnly'

  toggleFields: ->
    @constructor.__super__.toggleFields.call(this)
    type = @fieldValue('qtype_name')
    @togglePrefillPattern(type)

  togglePrefillPattern: (type) ->
    if @prefillableTypes.indexOf(type) != -1
      @$('.questioning_prefill_pattern').show()
      @$('.questioning_read_only').show()
    else
      @$('.questioning_prefill_pattern').hide()
      @$('.questioning_read_only').hide()

  toggleReadOnly: ->
    prefillValue = (@fieldValue('prefill_pattern') || '').trim()
    @$('.questioning_read_only')[if prefillValue == '' then 'hide' else 'show']()
