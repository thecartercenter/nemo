# Newer view to manage Question form.
class ELMO.Views.QuestionFormView extends ELMO.Views.FormView
  initialize: (options) ->
    @toggleFields()

  # We use $= because the start of the ID can vary depending on whether
  # it's a question form or questioning form.
  # Note, these events must be redefined in any child classes.
  events:
    'change select[id$="_qtype_name"]': 'toggleFields'
    'change select[id$="_metadata_type"]': 'toggleFields'

  toggleFields: ->
    @showField('auto_increment', @showAutoIncrement())
    @showField('metadata_type', @showMetaDataType())

  showAutoIncrement: ->
    @fieldValue('qtype_name') == 'counter'

  showMetaDataType: ->
    @fieldValue('qtype_name') == 'datetime'

  metadataTypeBlank: ->
    !@showMetaDataType() || @fieldValue('metadata_type') == ''

  # Gets form field value, or static value if field is read-only
  fieldValue: (attrib) ->
    div = @fieldElement(attrib)
    if div.is('.read-only')
      wrapper = div.find('.ro-val')
      if typeof wrapper.data('val') != 'undefined' then wrapper.data('val') else wrapper.text()
    else
      # Rails checkbox fields have a hidden field followed by a checkbox. We need to ignore the hidden.
      field = div.find('input[type!=hidden], select, textarea')
      if field.attr('type') == 'checkbox'
        field.is(':checked')
      else
        field.val()

  # Gets a data- value from the selected option for the given select-type field,
  # or from the div.ro-val tag if read only.
  selectedOptionData: (attrib, dataAttrib) ->
    div = @fieldElement(attrib)
    if div.is('.read-only')
      div.find('.ro-val').data(dataAttrib)
    else
      div.find('option:selected').data(dataAttrib)

  fieldElement: (attrib) ->
    @$(".form-field[data-field-name=#{attrib}] .control")
