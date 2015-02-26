class ELMO.Views.QuestionGroupDialogView extends Backbone.View

  initialize: ->
    question_group()

  el: '#form-items',

  events:
    'click #form-add-group': 'show_modal'
    'click .group-cancel': 'hide_modal'
    'click .group-save': 'hide_modal'

  question_group = ->
    $('#form-add-group').on 'click', (link) =>
      show_modal()

  save_group = ->
    # sendData()
    hide_modal()

  show_modal = ->
    $('#form-item-group-modal').modal('show')

  hide_modal = ->
    $('#form-item-group-modal').modal('hide')

  sendData = ->
   $.ajax({
      url: ELMO.app.url_builder.build('qing-groups', this.id),
      method: "post",
      data: {print: 1},
      success: (data) =>
        $('li').html(data).appendTo('.form-items-list')
        ELMO.app.loading(true)
    })
