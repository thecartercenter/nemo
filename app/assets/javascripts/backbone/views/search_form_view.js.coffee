# Models the form for entering a search query.
class ELMO.Views.SearchFormView extends Backbone.View

  el: '.search_form',

  events:
    'click .btn-clear': 'clear_search'
    'click .search-footer a': 'show_help'

  clear_search: (e) ->
    e.preventDefault()
    window.location.href = window.location.pathname

  show_help: ->
    $('#search-help-modal').modal('show')
