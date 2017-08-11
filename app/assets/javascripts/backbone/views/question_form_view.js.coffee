# Newer view to manage Question/Questioning form.
class ELMO.Views.QuestionFormView extends ELMO.Views.ApplicationView
  initialize: (options) ->
    @$('select[id$="_qtype_name"]').trigger('change')

  events:
    'change select[id$="_qtype_name"]': 'typeChanged'

  typeChanged: (e) ->
    new_type = @$(e.target).val()
    @$('.question_auto_increment')[if new_type == 'counter' then 'show' else 'hide']()
