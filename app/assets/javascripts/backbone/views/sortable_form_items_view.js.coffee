class ELMO.Views.SortableFormItemsView extends Backbone.View

  initialize: ->
    $('.form-items-list, .form-group ol').sortable({connectWith: ".item-list"})

  # Send position information to server
