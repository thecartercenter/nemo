class ELMO.Views.RepeatGroupFormView extends Backbone.View
  initialize: (options, additional_options) ->
    @html_string = additional_options.html_string

  events:
    'click .add-instance' : 'add_instance'

  add_instance: (event) ->
    event.preventDefault()
    console.log @html_string
