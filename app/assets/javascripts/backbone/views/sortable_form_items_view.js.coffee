class ELMO.Views.SortableFormItemsView extends Backbone.View

  initialize: ->
    $('.form-items-list').sortable()
    $('.form-group ol').sortable()
    $('.form-group ol').droppable()

  # Sortable list

  # Send information to server
