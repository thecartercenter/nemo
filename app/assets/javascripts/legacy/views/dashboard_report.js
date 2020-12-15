// ELMO.Views.DashboardReport
//
// View model for the dashboard report
(function(ns, klass) {
  // constructor
  ns.DashboardReport = klass = function(dashboard, params) {
    const self = this;
    self.dashboard = dashboard;
    self.params = params;

    // save the report id
    if (params) self.current_report_id = self.params.id;

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

  klass.prototype.refresh = function() {
    if (!ELMO.app.report_controller) return;
    const self = this;
    $('.report-pane .inline-load-ind img').show();
    ELMO.app.report_controller.run_report().then(() => self.display_report());
  };

  klass.prototype.change_report = function(id, name) {
    const self = this;
    self.current_report_id = id;

    $('.report-pane .report-title-text').html(name);
    $('.report-pane .inline-load-ind img').show();
    $('.report-main').empty();
    $('.report-chooser select').val('');
    $('.report-edit-link-container').hide();
    $('.report-main').load(ELMO.app.url_builder.build('reports', id), () => self.display_report());
  };

  klass.prototype.display_report = function() {
    $('.report-pane .report-title-text').html(this.report().attribs.name);
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
