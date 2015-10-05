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

    // Load report via Ajax on the first time page is displayed.
    if (self.current_report_id) {
      self.show_loading_message();
      self.load_report(self.current_report_id);
    }
  };

  klass.prototype.hookup_report_chooser = function () { var self = this;
    $('.report_pane').on('change', 'form.report_chooser', function(e){
      var report_id = $(e.target).val();

      self.clear_report_data();
      self.show_loading_message();

      if (report_id) self.load_report(report_id);
    });
  };

  klass.prototype.clear_report_data = function() { var self = this;
    $('.report_body').empty();
    $('.report_info').empty();
  }
  klass.prototype.show_loading_message = function() { var self = this;
    $('.report_pane h2 .report_title_text').html(I18n.t('report/report.loading_report'));
  }

  klass.prototype.load_report = function(id) { var self = this;
    // save the ID
    self.current_report_id = id;

    // send ajax request and replace div contents
    return $.get(ELMO.app.url_builder.build('report-update', id))
      .done(function(data){
        ELMO.app.report_controller = new ELMO.Report.ReportController(data);

        // clear the dropdown for the next choice
        $('.report_chooser select').val("");
      });
  };

}(ELMO.Views));
