# Newer view to manage Questioning form.
class ELMO.Views.QuestioningFormView extends ELMO.Views.QuestionFormView
  initialize: (options) ->
    @super = @constructor.__super__
    @defaultableTypes = options.defaultableTypes
    @toggleFields()

  events:
    'change select[id$="_qtype_name"]': 'toggleFields'
    'change select[id$="_metadata_type"]': 'toggleFields'
    'click #questioning_read_only': 'toggleFields'
    'keyup #questioning_default': 'toggleFields'

  toggleFields: ->
    @super.toggleFields.call(this)
    @showField('default', @showDefault())
    @showField('read_only', @showReadOnly())
    @showField('required', @showRequired())
    @showField('hidden', @showHidden())
    @showField('condition', @showCondition())

  showDefault: ->
    @defaultableTypes.indexOf(@fieldValue('qtype_name')) != -1

  showReadOnly: ->
    @showDefault() && (@fieldValue('default') || '').trim() != ''

  showRequired: ->
    !@fieldValue('read_only') && @super.metadataTypeBlank.call(this)

  showHidden: ->
    @super.metadataTypeBlank.call(this)

  showCondition: ->
    @super.metadataTypeBlank.call(this)
