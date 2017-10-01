# Newer view to manage Questioning form.
class ELMO.Views.QuestioningFormView extends ELMO.Views.QuestionFormView
  initialize: (options) ->
    @super = @constructor.__super__
    @prefillableTypes = options.prefillableTypes
    @toggleFields()

  events:
    'change select[id$="_qtype_name"]': 'toggleFields'
    'change select[id$="_metadata_type"]': 'toggleFields'
    'click #questioning_read_only': 'toggleFields'
    'keyup #questioning_prefill_pattern' : 'toggleFields'

  toggleFields: ->
    @super.toggleFields.call(this)
    @$('.questioning_prefill_pattern')[if @showPrefillPattern() then 'show' else 'hide']()
    @$('.questioning_read_only')[if @showReadOnly() then 'show' else 'hide']()
    @$('.questioning_required')[if @showRequired() then 'show' else 'hide']()
    @$('.questioning_hidden')[if @showHidden() then 'show' else 'hide']()
    @$('.questioning_condition')[if @showCondition() then 'show' else 'hide']()

  showPrefillPattern: ->
    @prefillableTypes.indexOf(@fieldValue('qtype_name')) != -1

  showReadOnly: ->
    @showPrefillPattern() && (@fieldValue('prefill_pattern') || '').trim() != ''

  showRequired: ->
    !@fieldValue('read_only') && @super.metadataTypeBlank.call(this)

  showHidden: ->
    @super.metadataTypeBlank.call(this)

  showCondition: ->
    @super.metadataTypeBlank.call(this)
