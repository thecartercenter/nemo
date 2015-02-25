class ELMO.Views.SortableFormItemsView extends Backbone.View

  initialize: ->
    $('.questions-list').sortable()

  # Sortable list

  # Send information to server
