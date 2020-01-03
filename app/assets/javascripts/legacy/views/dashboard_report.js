// ELMO.Views.DashboardReport
//
// View model for the dashboard report
(function (ns, klass) {
  // constructor
  ns.DashboardReport = klass = function (dashboard, params) {
    const self = this;
    self.dashboard = dashboard;
    self.params = params;

    // save the report id
    if (params) self.current_report_id = self.params.id;

    // hookup the form change event
    self.hookup_report_chooser();
  };

  klass.prototype.hookup_report_chooser = function () {
    const self = this;
    $('.report_pane').on('change', 'form.report_chooser', (e) => {
      const report_id = $(e.target).val();
      if (report_id) self.change_report(report_id);
    });
  };

  klass.prototype.refresh = function () {
    if (!ELMO.app.report_controller) return;

    const self = this;
    ELMO.app.report_controller.run_report().then(() => {
      $('.report_pane h2').html(self.report().attribs.name);
      self.set_edit_link();
      $('.report_chooser').show();
    });
  };

  klass.prototype.change_report = function (id) {
    const self = this;
    // save the ID
    self.current_report_id = id;

    // show loading message
    $('.report_pane h2').html(I18n.t('report/report.loading_report'));

    // remove the old content and replace with new stuff
    $('.report_main').empty();
    $('.report_main').load(ELMO.app.url_builder.build('reports', id),
      () => {
        $('.report_pane h2').html(self.report().attribs.name);
        self.set_edit_link();
        $('.report_chooser').show();
      });

    // clear the dropdown for the next choice
    $('.report_chooser select').val('');

    // Hide edit link and chooser until reload is finished
    $('.report_edit_link_container').hide();
    $('.report_chooser').hide();
  };

  klass.prototype.reset_title_pane_text = function (title) {
    $('.report_title_text').text(title);
  };

  klass.prototype.set_edit_link = function (data) {
    if (this.report().attribs.user_can_edit) {
      report_url = `${ELMO.app.url_builder.build('reports', this.report().attribs.id)}/edit`;

      $('.report_edit_link_container').show();
      $('.report_edit_link_container a').attr('href', report_url);
    } else {
      $('.report_edit_link_container').hide();
      $('.report_edit_link_container a').attr('href', '');
    }
  };

  klass.prototype.report = function () {
    return ELMO.app.report_controller.report_last_run;
  };
}(ELMO.Views));
