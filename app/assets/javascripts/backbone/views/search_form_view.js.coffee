# Models the form for entering a search query.
class ELMO.Views.SearchFormView extends Backbone.View

  el: '.search_form',

  events:
    'click .btn-clear': 'clear_search'
    'click .search-footer a': 'show_help'

  clear_search: (e) ->
    e.preventDefault()
    window.location.href = window.location.pathname

  show_help: (e) ->
    e.preventDefault()
    $('#search-help-modal').modal('show')

  # Add or replace the specified search qualifier
  setQualifier: (qualifier, val) ->
    search_box = this.$('#search_str')
    current_search = search_box.val()

    # Remove the qualifier text if it's already in the current search
    regex = /// #{qualifier}: \s* ( \w+ | \( .* \) | " .* " ) \s? ///g
    current_search = current_search.replace(regex, '').trim()

    # Surround new value with quotes if contains space
    val = val.replace(/^(.*\s+.*)$/, '"$1"')

    # Add new qualifier to end of search
    if current_search
      search_box.val(current_search + " #{qualifier}:#{val}")
    else
      search_box.val("#{qualifier}:#{val}")

    # Submit form
    @el.submit()
