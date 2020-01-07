// ELMO.Views.ReportAjaxLoader
//
// View model to load the report via ajax. Used on dashboard and report show.
(function (ns, klass) {
  // constructor
  ns.ReportAjaxLoader = klass = function (params, dashboard) {
    const self = this;
    self.dashboard = dashboard;
    self.params = params;

    // save the report id
    if (params) {
      self.current_report_id = self.params.id;
      self.edit_mode = self.params.edit_mode;
    }

    // Load report via Ajax on the first time page is displayed.
    if (self.current_report_id) {
      self.load_report(self.current_report_id, self.edit_mode, self.dashboard);
    }
  };

  klass.prototype.load_report = function (id, edit_mode, dashboard, dont_show_loading) {
    const self = this;
    // save the ID
    self.current_report_id = id;

    // This is an optional parameter that is used when called
    // from dashboard reload action
    if (!dont_show_loading) {
      $('.report_loading_icon').show();
    }

    if (self.current_report_id) {
      // send ajax request and replace div contents
      return $.ajax({
        url: ELMO.app.url_builder.build('report-update', id),
        method: 'GET',
        data: {
          id,
          edit_mode,
          dashboard: (dashboard ? 'true' : 'false'),
        },
        success(data) {
          ELMO.app.report_controller = new ELMO.Report.ReportController(data);
          $('.report_loading_icon').hide();
        },
      });
    }
    // Return a resolved promise to keep function return consistency
    // (because this is what the ajax call returns)
    return $.Deferred().resolve().promise();
  };
}(ELMO.Views));
