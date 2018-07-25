class ELMO.Views.RepeatGroupFormView extends ELMO.Views.ApplicationView
  events:
    'click .add-repeat': 'add_repeat'
    'click .remove-repeat': 'remove_repeat'

  initialize: (options) ->
    @tmpl = options.tmpl
    @next_index = options.next_index

  children: ->
    this.$el.find("> .children")

  add_repeat: (event) ->
    event.preventDefault()
    this.children().append(@tmpl.replace(/__PLACEHOLDER__/g, @next_index))
    @next_index++

  remove_repeat: (event) ->
    event.preventDefault()
    node = $(event.target).closest(".node")
    node.hide();

    id = node.find('input[name$="[id]"]').first().val()
    if id == ""
      node.remove()
    else
      node.hide()
      node.find('input[name$="[_destroy]"]').first().val("true")
