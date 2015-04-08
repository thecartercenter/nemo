class ELMO.Views.CascadingSelectsView extends Backbone.View

  initialize: (options) ->
    @option_set_id = options.option_set_id
    @cur_val = this.val()

  events:
    'change select': 'select_changed'

  # private --------

  select_changed: (event) ->
    if this.value_changed() && next = this.next_select($(event.target))
      this.clear_selects_after_and_including(next)
      this.reload_options_for(next)

  # Gets the next select box after the given one.
  # Returns false if not found.
  next_select: (select) ->
    next = select.closest('div').next().find('select')
    next.length > 0 && next || false

  # Clears all selects after and including the given one.
  clear_selects_after_and_including: (select) ->
    select.empty().html('<option></option>')
    this.clear_selects_after_and_including(next) if next = this.next_select(select)

  # Fetches option tags for the given select from the server.
  reload_options_for: (select) ->
    ELMO.app.loading(true)
    vals = this.selected_values_before(select)
    url = ELMO.app.url_builder.build('option-sets', @option_set_id, 'options-for-node')
    select.load(url, $.param({ids: vals}), -> ELMO.app.loading(false))

  # Gets the values of the selects before the given one.
  selected_values_before: (select) ->
    this.selects_before(select).get().map((s) -> $(s).val())

  # Gets all the select tags before the given one.
  selects_before: (select) ->
    select.parent().prevAll().find('select')

  # Gets an array of values of all the selects.
  val: ->
    (@$('select').map -> $(this).val()).get()

  # Checks if the value changed since last inspection. If so, saves new value
  value_changed: ->
    new_val = this.val()
    if @cur_val.join('__') != new_val.join('__')
      @cur_val = new_val
      true
    else
      false

