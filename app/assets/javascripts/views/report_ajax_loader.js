// ELMO.Views.ReportAjaxLoader
//
// View model to load the report via ajax. Used on dashboard and report show.
(function(ns, klass) {

  // constructor
  ns.ReportAjaxLoader = klass = function(params, dashboard) { var self = this;
    self.dashboard = dashboard;
    self.params = params;

    // save the report id
    if (params) {
      self.current_report_id = self.params.id;
      self.edit_mode = self.params.edit_mode;
    }

    if (dashboard) {
      // hookup the form change event
      self.hookup_report_chooser();
      self.show_loading_message();
    }

    // Load report via Ajax on the first time page is displayed.
    if (self.current_report_id) {
      self.load_report(self.current_report_id, self.edit_mode, self.dashboard);
    }
  };

  klass.prototype.hookup_report_chooser = function () { var self = this;
    $('.report_pane').on('change', 'form.report_chooser', function(e){
      var report_id = $(e.target).val();

      self.clear_report_data();
      self.show_loading_message();

      if (report_id) self.load_report(report_id, self.edit_mode, self.dashboard);
    });
  };

  klass.prototype.clear_report_data = function() { var self = this;
    $('.report_body').empty();
    $('.report_info').empty();
  }
  klass.prototype.show_loading_message = function() { var self = this;
    $('.report_pane h2 .report_title_text').html(I18n.t('report/report.loading_report'));
  }

  klass.prototype.load_report = function(id, edit_mode, dashboard) { var self = this;
    // save the ID
    self.current_report_id = id;

    $('.report_loading_icon').show();

    if (self.current_report_id) {
      // send ajax request and replace div contents
      return $.ajax({
        url: ELMO.app.url_builder.build('report-update', id),
        method: 'GET',
        data: {
          id: id,
          edit_mode: edit_mode,
          dashboard: (dashboard ? 'true' : 'false')
        },
        success: function(data){
          ELMO.app.report_controller = new ELMO.Report.ReportController(data);

          // clear the dropdown for the next choice
          $('.report_chooser select').val("");

          $('.report_loading_icon').hide();
        }
      });
    } else {
      // Return a resolved promise to keep function return consistency
      // (because this is what the ajax call returns)
      return $.Deferred().resolve().promise();
    }
  };

}(ELMO.Views));
