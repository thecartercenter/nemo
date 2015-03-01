class ELMO.Views.QuestionGroupDialogView extends Backbone.View

  initialize: ->
    question_group()

  el: '.form-items',

  events:
    'click .form-add-group': 'show_modal'
    'click .group-save': 'save_group'

  question_group = ->
    $('.form-add-group').on 'click', (link) =>
      show_modal()
    $('.group-save').on 'click', (button) =>
      save_group()

  save_group = ->
    update_group()
    hide_modal()

  show_modal = ->
    $('.group-modal').modal('show')

  hide_modal = ->
    $('.group-modal').modal('hide')

  update_group = ->
    send_data()

  send_data = ->
    form_data = $('.qing_group_form').serialize()
    console.log(form_data)

    $.ajax({
      url: ELMO.app.url_builder.build('qing-groups', this.id),
      method: "post",
      # data: {qing_group: { form_id: FORM_ID, group_name_translations: {en: GROUP_NAME  }}},
      data: form_data,
      success: (data) =>
        $('<li>').html(data).appendTo('.form-items-list')
        console.log(data)
        ELMO.app.loading(true)
    })
