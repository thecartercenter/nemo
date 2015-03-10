class ELMO.Views.FormItemsView extends Backbone.View

  el: '.form-items'

  events:
    'click .add-group': 'show'
    'click .form-group .edit': 'edit'

  initialize: ->
    $('.form-items-list').nestedSortable()

  show: ->
    show_modal()

  edit:(e) ->
    e.preventDefault()
    show_modal()

  show_modal = ->
    console.log("Show modal was clicked")
    new ELMO.Views.GroupModalView();
    console.log("Group modal called.")

  send_data = ->
    $.ajax({
      url: ELMO.app.url_builder.build('qing-groups', this.id),
      method: "post",
      data: form_data,
      success: (data) =>
        $('<li>').html(data).appendTo('.form-items-list')
        console.log(data)
        ELMO.app.loading(false)
    })
