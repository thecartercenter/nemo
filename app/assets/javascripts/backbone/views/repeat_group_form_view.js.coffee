class ELMO.Views.RepeatGroupFormView extends ELMO.Views.ApplicationView
  initialize: (options) ->
    @tmpl = options.tmpl
    @next_inst_num = parseInt(@$el.data('inst-count')) + 1

  events:
    'click .add-instance' : 'add_instance'
    'click .remove-instance': 'remove_instance'

  add_instance: (event) ->
    event.preventDefault()
    qing_group = $(event.target).closest('.qing-group')
    qing_group.find('.qing-group-instances').append(@tmpl.replace(/__INST_NUM__/g, @next_inst_num))
    @next_inst_num++

  remove_instance: (event) ->
    event.preventDefault()
    instance = $(event.target.closest('.qing-group-instance'))
    instance.hide()
    instance.find("[id$=_destroy]").val("1")
