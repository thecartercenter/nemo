class ELMO.Views.RepeatGroupFormView extends ELMO.Views.ApplicationView
  initialize: (options) ->
    @tmpl = options.tmpl
    @next_new_rank = parseInt(@$el.data('new-rank'))

  events:
    'click .add-instance': 'add_instance'
    'click .remove-instance': 'remove_instance'

  add_instance: (event) ->
    event.preventDefault()
    group = $(event.target).closest('.answer-group-set')
    group.find('> .children').append(@tmpl.replace(/__NEW_RANK__/g, @next_new_rank))
    @next_new_rank++

  remove_instance: (event) ->
    event.preventDefault()
    node = $(event.target.closest('.answer-group-set .children'))
    node.hide()
    node.find("[id$=_destroy]").val("1")
