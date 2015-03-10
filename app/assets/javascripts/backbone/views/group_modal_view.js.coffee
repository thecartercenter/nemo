class ELMO.Views.GroupModalView extends Backbone.View
# class ELMO.Views.GroupModalView extends ELMO.Views.FormItemsView

  el: 'body'

  events:
    'click .save': 'save'
    'click .test-modal': 'open'

  intialize: (list_view) ->
    this.list_view = list_view
    show()

  open: ->
    show()

  save: ->
    form_data = $('.qing_group_form').serialize()
    console.log(form_data)
    return form_data
    hide()

  show = ->
    $('.group-modal').modal('show')

  hide = ->
    $('.group-modal').modal('hide')
