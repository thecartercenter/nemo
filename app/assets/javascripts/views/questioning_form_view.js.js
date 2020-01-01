# Newer view to manage Questioning form.
class ELMO.Views.QuestioningFormView extends ELMO.Views.QuestionFormView
  initialize: (options) ->
    @super = @constructor.__super__
    @defaultableTypes = options.defaultableTypes
    @toggleFields()

  events:
    'change select[id$="_qtype_name"]': 'toggleFields'
    'change select[id$="_option_set_id"]': 'toggleFields'
    'change select[id$="_metadata_type"]': 'toggleFields'
    'click #questioning_read_only': 'toggleFields'
    'click #questioning_required': 'toggleFields'
    'keyup #questioning_default': 'toggleFields'

  toggleFields: ->
    @super.toggleFields.call(this)
    @showField('default', @showDefault())
    @showField('read_only', @showReadOnly())
    @showField('required', @showRequired())
    @showField('all_levels_required', @showAllLevelsRequired())
    @showField('hidden', @showHidden())
    @showField('display_logic', @showDisplayLogic())
    @showField('skip_logic', @showSkipLogic())

  showDefault: ->
    @defaultableTypes.indexOf(@fieldValue('qtype_name')) != -1

  showReadOnly: ->
    @showDefault() && (@fieldValue('default') || '').trim() != ''

  showRequired: ->
    !@fieldValue('read_only') && @super.metadataTypeBlank.call(this)

  showAllLevelsRequired: ->
    @showRequired() &&
      @fieldValue('required').toString() == 'true' &&
      @fieldValue('qtype_name') == 'select_one' &&
      @selectedOptionData('option_set_id', 'multilevel')

  showHidden: ->
    @super.metadataTypeBlank.call(this)

  showDisplayLogic: ->
    @super.metadataTypeBlank.call(this)

  showSkipLogic: ->
    @super.metadataTypeBlank.call(this)
