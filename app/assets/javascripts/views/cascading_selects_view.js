/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
ELMO.Views.CascadingSelectsView = class CascadingSelectsView extends ELMO.Views.ApplicationView {
  get events() { return { 'change select': 'select_changed' }; }

  initialize(options) {
    this.option_set_id = options.option_set_id;
    return this.cur_val = this.val();
  }

  // private --------

  select_changed(event) {
    let next;
    if (this.value_changed() && (next = this.next_select($(event.target)))) {
      this.clear_selects_after_and_including(next);
      return this.reload_options_for(next);
    }
  }

  // Gets the next select box after the given one.
  // Returns false if not found.
  next_select(select) {
    const next = select.closest('div').next().find('select');
    return ((next.length > 0) && next) || false;
  }

  // Clears all selects after and including the given one.
  clear_selects_after_and_including(select) {
    let next;
    select.empty().html('<option></option>');
    if (next = this.next_select(select)) { return this.clear_selects_after_and_including(next); }
  }

  // Fetches option tags for the given select from the server.
  reload_options_for(select) {
    ELMO.app.loading(true);
    const node_id = this.selected_value_before(select);
    const url = ELMO.app.url_builder.build('option-sets', this.option_set_id, 'child-nodes');
    return select.load(url, $.param({ node_id }), () => ELMO.app.loading(false));
  }

  selected_value_before(select) {
    return select.closest('div.level').prev().find('select').val();
  }

  // Gets an array of values of all the selects.
  val() {
    return (this.$('select').map(function () { return $(this).val(); })).get();
  }

  // Checks if the value changed since last inspection. If so, saves new value
  value_changed() {
    const new_val = this.val();
    if (this.cur_val.join('__') !== new_val.join('__')) {
      this.cur_val = new_val;
      return true;
    }
    return false;
  }
};
