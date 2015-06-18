// ELMO.Views.DashboardReport
//
// View model for the dashboard report
(function(ns, klass) {

  // constructor
  ns.DashboardReport = klass = function(dashboard, params) { var self = this;
    self.dashboard = dashboard;
    self.params = params;

    // save the report id
    if (params)
      self.current_report_id = self.params.id;

    // hookup the form change event
    self.hookup_report_chooser();
  };

  klass.prototype.hookup_report_chooser = function () { var self = this;
    $('.report_pane').on('change', 'form.report_chooser', function(e){
      var report_id = $(e.target).val();
      if (report_id) self.load_report(report_id);
    });
  };

  klass.prototype.load_report = function(id) { var self = this;
    // save the ID
    self.current_report_id = id;

    // show loading message
    $('.report_pane h2').html(I18n.t('report/report.loading_report'));

    // remove the old content
    $('.report_main').empty();

    // send ajax request and replace div contents
    $.get(ELMO.app.url_builder.build('report-update', id))
    .done(function(data){
      $('.report_title').html(data.title);
      $('.report_main').html(data.main);
    });

    // clear the dropdown for the next choice
    $('.report_chooser select').val("");
  };

}(ELMO.Views));
