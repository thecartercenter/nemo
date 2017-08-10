# Newer view to manage question form (or question fields on questioning form).
class ELMO.Views.QuestionFormView extends ELMO.Views.ApplicationView
  initialize: (options) ->
    @$('select[id$="_qtype_name"]').trigger('change')

  events:
    'change select[id$="_qtype_name"]': 'typeChanged'

  typeChanged: (e) ->
    new_type = @$(e.target).val()
    @$('.question_auto_increment')[if new_type == 'counter' then 'show' else 'hide']()
