class ELMO.Views.QuestionGroupDialogView extends Backbone.View

  initialize: ->
    questionGroup()

  questionGroup = ->
    $('.q-addGroup').on 'click', (link) =>
      displayDialog()
    $('.add-group-cancel').on 'click', (button) =>
      hideDialog()
    $('.add-group-save').on 'click', (button) =>
      hideDialog()

  displayDialog = ->
    $('#addQuestionGroupModal').css('display', 'block').css('opacity', 1).css('padding-top', '200px')

  hideDialog = ->
    $('#addQuestionGroupModal').css('display', '').css('opacity', '').css('padding-top', '')
