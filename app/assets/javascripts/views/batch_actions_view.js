/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// Models the batch actions done on index pages
ELMO.Views.BatchActionsView = class BatchActionsView extends ELMO.Views.ApplicationView {
  get el() { return '.index-table-wrapper'; }

  get events() {
    return {
      'click #select-all-link': 'select_all_clicked',
      'click a.select_all_pages': 'select_all_pages_clicked',
      'click a.batch-submit-link': 'submit_batch',
      'change input[type=checkbox].batch_op': 'checkbox_changed',
    };
  }

  initialize(params, search_form_view) {
    this.form = this.$el.find('form').first() || this.$el.closest('form');
    this.select_all_pages_field = this.$el.find('input[name=select_all_pages]');
    this.alert = this.$el.find('div.alert');
    this.entries = this.$el.data('entries');
    this.class_name = I18n.t(`activerecord.models.${params.class_name}.many`);
    this.search_form_view = search_form_view;
    this.pages = this.$el.data('pages');

    // flash the modified obj if given
    if (params.modified_obj_id) {
      $(`#${params.class_name}_${params.modified_obj_id}`).effect('highlight', {}, 1000);
    }

    if (params.batch_ops) {
      return this.update_links();
    }
  }

  // selects/deselects all boxes on page
  select_all_clicked(event) {
    event.preventDefault();
    this.toggle_all_boxes(!this.all_checked());
    this.set_select_all_pages_true_if_all_checked_and_only_one_page_else_false();
    return this.update_links();
  }

  select_all_pages_clicked(event) {
    event.preventDefault();
    this.select_all_pages_field.val('1');
    return this.update_links();
  }

  checkbox_changed(event) {
    this.set_select_all_pages_true_if_all_checked_and_only_one_page_else_false();
    return this.update_links();
  }

  reset_alert() {
    return this.alert.stop().hide()
      .removeClass('alert-danger alert-info alert-warning alert-success').removeAttr('opacity');
  }

  // Updates the select all link and the select all pages notice.
  update_links() {
    let msg;
    const label = this.all_checked() ? 'deselect_all' : 'select_all';
    $('#select-all-link').html(I18n.t(`layout.${label}`));

    this.reset_alert();

    if (this.select_all_pages_field.val()) {
      msg = I18n.t('index_table.messages.selected_all_rows', { class_name: this.class_name, count: this.entries });
      this.alert.html(msg);
      return this.alert.addClass('alert-info').show();
    } else if ((this.pages > 1) && this.all_checked()) {
      msg = `${I18n.t('index_table.messages.selected_rows_page',
        { class_name: this.class_name, count: this.get_selected_count() })} `
        + `<a href='#' class='select_all_pages'>${
          I18n.t('index_table.messages.select_all_rows', { class_name: this.class_name, count: this.entries })
        }</a>`;
      this.alert.html(msg);
      return this.alert.addClass('alert-info').show();
    }
  }

  // gets all checkboxes in batch_form
  get_batch_checkboxes() {
    return this.form.find('input[type=checkbox].batch_op');
  }

  get_selected_count() {
    if (this.select_all_pages_field.val()) {
      return this.entries;
    }
    return _.size(_.filter(this.get_batch_checkboxes(), (cb) => cb.checked));
  }

  get_selected_items() {
    return this.form.find('input.batch_op:checked');
  }

  toggle_all_boxes(bool) {
    const cbs = this.get_batch_checkboxes();
    return Array.from(cbs).map((cb) => (cb.checked = bool));
  }

  // tests if all boxes are checked
  all_checked() {
    const cbs = this.get_batch_checkboxes();
    return _.every(cbs, (cb) => cb.checked);
  }

  set_select_all_pages_true_if_all_checked_and_only_one_page_else_false() {
    return this.select_all_pages_field.val(this.all_checked() && (this.pages === 1) ? '1' : '');
  }

  // submits the batch form to the given path
  submit_batch(event) {
    event.preventDefault();

    const options = $(event.target).data();

    // ensure there is at least one item selected, and error if not
    const selected = this.get_selected_count();
    if (selected === 0) {
      this.alert.html(I18n.t('layout.no_selection')).addClass('alert-danger').show();
      this.alert.delay(2500).fadeOut('slow', this.reset_alert.bind(this));

    // else, show confirm dialog (if requested), and proceed if 'yes' clicked
    } else if (!options.confirm || confirm(I18n.t(options.confirm, { count: selected }))) {
      // construct a temporary form
      //
      // TODO: This fake DOM submission logic is old, hacky, and should be refactored eventually.
      //   Perhaps it could be a simple AJAX request which updates the paginated list on success.
      const form = $('<form>').attr('action', options.path).attr('method', 'post').attr('style', 'display: none');

      // copy the checked checkboxes to it, along with the select_all field
      // (we do it this way in case the main form has other stuff in it that we don't want to submit)
      form.append(this.form.find('input.batch_op:checked').clone());
      form.append(this.form.find('input[name=select_all_pages]').clone());
      const pages_field = this.form.find('input[name=pages]');
      pages_field.val(this.pages);
      form.append(pages_field.clone());
      if (this.search_form_view) {
        form.append(this.search_form_view.$el.find('input[name=search]').clone());
      }

      const token = $('meta[name="csrf-token"]').attr('content');
      $('<input>').attr({ type: 'hidden', name: 'authenticity_token', value: token }).appendTo(form);

      form.appendTo($('body'));
      form.submit();
    }

    return false;
  }
};
