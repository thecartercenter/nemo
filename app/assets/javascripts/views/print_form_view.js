/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
ELMO.Views.PrintFormView = class PrintFormView extends ELMO.Views.ApplicationView {
  get el() { return '#content'; }

  get events() { return { 'click a.print-link': 'print_form' }; }

  initialize() {
    // For some reason this doesn't work if you put it in the events hash.
    return $('#form-print-format-tips').on('hidden.bs.modal', () => this.load_printable_form());
  }

  print_form(e) {
    e.preventDefault();

    this.id = $(e.currentTarget).data('form-id');

    if (this.should_show_format_tips()) {
      return this.show_format_tips_modal();
    }
    return this.load_printable_form();
  }

  load_printable_form() {
    ELMO.app.loading(true);

    // Delete any previous print content stuff in case print multiple times.
    $('.print-content').remove();

    // Load specially formatted show page into div.
    return $.ajax({
      url: ELMO.app.url_builder.build('forms', this.id),
      method: 'get',
      headers: {
        accept: 'text/html',
      }, // Without this, we get 404 due to route constraints.
      data: { print: 1 },
      success: (data) => {
        $('<div>').addClass('print-content').html(data).appendTo(this.$el);
        ELMO.app.loading(false);
        return this.do_print();
      },
    });
  }

  should_show_format_tips() {
    // Show if not already shown today.
    return window.localStorage.getItem('form_print_format_tips_shown') !== this.datestamp();
  }

  show_format_tips_modal() {
    window.localStorage.setItem('form_print_format_tips_shown', this.datestamp());
    return $('#form-print-format-tips').modal('show');
  }

  // Shows the print dialog, or just a dummy modal if in test mode.
  do_print() {
    return window.print();
  }

  // Returns a date in yyyy-mm-dd format.
  datestamp() {
    // TODO: Clean up this logic with Moment when we migrate to package.json dependencies.
    const d = new Date();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${d.getFullYear()}-${month}-${day}`;
  }
};
