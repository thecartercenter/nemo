class ELMO.Views.ResponseFormRepeatView extends ELMO.Views.ApplicationView
  events:
    'click > .add-repeat': 'addRepeat'
    'click .remove-repeat': 'removeRepeat'

  initialize: (options) ->
    @tmpl = options.tmpl
    @next_index = options.next_index

    # If this ID remains in the DOM and a new copy of the template is inserted,
    # the Backbone view instance for the newly inserted one won't know which of
    # them to bind to
    @$el.removeAttr("id")

  children: ->
    @$("> .children")

  addRepeat: (event) ->
    event.preventDefault()
    @children().append(@tmpl.replace(/__INDEX__/g, @next_index))
    @next_index++

  removeRepeat: (event) ->
    event.preventDefault()
    node = $(event.target).closest(".node")

    id = node.find('input[name$="[id]"]').first().val()
    if id == ""
      node.remove()
    else
      node.hide()
      node.find('input[name$="[_destroy]"]').first().val("true")
