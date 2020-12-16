// ELMO.Views.DashboardReport
//
// View model for the dashboard report
(function(ns, klass) {
  // constructor
  ns.DashboardReport = klass = function() {
    const self = this;

    // hookup the form change event
    self.hookup_report_chooser();
  };

  klass.prototype.hookup_report_chooser = function() {
    const self = this;
    $('.report-pane').on('change', 'form.report-chooser', (e) => {
      const id = $(e.target).val();
      if (id) {
        self.change_report(id, $(e.target).find('option:selected').text());
      }
    });
  };

  klass.prototype.change_report = function(id, name) {
    const self = this;

    $('.report-pane .report-title-text').html(name);
    $('.report-pane .inline-load-ind img').show();
    $('.report-output').empty();
    $('.report-chooser select').val('');
    $('.report-edit-link-container').hide();
    $('.report-output-and-modal').load(ELMO.app.url_builder.build('reports', id), () => self.display_report());
  };

  klass.prototype.display_report = function() {
    $('.report-pane .inline-load-ind img').hide();
    this.set_edit_link();
  }

  klass.prototype.set_edit_link = function(data) {
    if (this.report().attribs.user_can_edit) {
      const report_url = `${ELMO.app.url_builder.build('reports', this.report().attribs.id)}/edit`;

      $('.report-edit-link-container').show();
      $('.report-edit-link-container a').attr('href', report_url);
    } else {
      $('.report-edit-link-container').hide();
      $('.report-edit-link-container a').attr('href', '');
    }
  };

  klass.prototype.report = function() {
    return ELMO.app.report_controller.report_last_run;
  };
}(ELMO.Views));
