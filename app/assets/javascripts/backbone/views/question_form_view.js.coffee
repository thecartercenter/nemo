# Newer view to manage Question form.
class ELMO.Views.QuestionFormView extends ELMO.Views.ApplicationView
  initialize: (options) ->
    @toggleFields()

  events:
    'change select[id$="_qtype_name"]': 'typeChanged'

  typeChanged: (e) ->
    @toggleFields()

  toggleFields: ->
    type = @fieldValue('qtype_name')
    @toggleAutoIncrement(type)

  toggleAutoIncrement: (type) ->
    @$('.question_auto_increment')[if type == 'counter' then 'show' else 'hide']()

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
