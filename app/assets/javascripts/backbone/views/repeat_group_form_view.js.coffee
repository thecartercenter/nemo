class ELMO.Views.RepeatGroupFormView extends Backbone.View
  initialize: (options, additional_options) ->
    @template = additional_options.template

  events:
    'click .add-instance' : 'add_instance'
    'click .remove-instance': 'remove_instance'

  add_instance: (event) ->
    event.preventDefault()
    qing_group = $(event.target).closest('.qing-group')
    qing_group.find('.qing-group-instances').append(@template)

  remove_instance: (event) ->
    event.preventDefault()
    instance = $(event.target.closest('.qing-group-instance'))
    instance.remove()
