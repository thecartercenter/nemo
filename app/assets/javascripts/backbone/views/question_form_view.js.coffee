# Newer view to manage Question form.
class ELMO.Views.QuestionFormView extends ELMO.Views.ApplicationView
  initialize: (options) ->
    @toggleFields()

  # We use $= because the start of the ID can vary depending on whether
  # it's a question form or questioning form.
  # Note, these events must be redefined in any child classes.
  events:
    'change select[id$="_qtype_name"]': 'toggleFields'
    'change select[id$="_metadata_type"]': 'toggleFields'

  toggleFields: ->
    @$('.question_auto_increment')[if @showAutoIncrement() then 'show' else 'hide']()
    @$('.question_metadata_type')[if @showMetaDataType() then 'show' else 'hide']()
    @$('.names_hints')[if @showTitleHint() then 'show' else 'hide']()

  showAutoIncrement: ->
    @fieldValue('qtype_name') == 'counter'

  showTitleHint: ->
    @metadataTypeBlank()

  showMetaDataType: ->
    @fieldValue('qtype_name') == 'datetime'

  metadataTypeBlank: ->
    !@showMetaDataType() || @fieldValue('metadata_type') == ''

  # Gets form field value, or static value if field is read-only
  fieldValue: (attrib) ->
    div = @$(".form_field[data-field-name=#{attrib}] .control")
    if div.is('.read_only')
      wrapper = div.find('.ro-val')
      wrapper.data('val') || wrapper.text()
    else
      # Rails checkbox fields have a hidden field followed by a checkbox. We need to ignore the hidden.
      field = div.find('input[type!=hidden], select, textarea')
      if field.attr('type') == 'checkbox'
        field.is(':checked')
      else
        field.val()
