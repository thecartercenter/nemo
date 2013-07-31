// ELMO.Views.DashboardReport
//
// View model for the dashboard report
(function(ns, klass) {
  
  // constructor
  ns.DashboardReport = klass = function(params) { var self = this;
    self.params = params;
    
    // load the report given in params.id
    self.load_report(self.params.id);
    
    // hookup the form change event
    $('form.report_chooser').on('change', function(e){ 
      var report_id = $(e.target).val();
      if (report_id) self.load_report(report_id);
    });
  };
  
  klass.prototype.load_report = function(id) { var self = this;
    // show loading message
    $('.report_main').html(I18n.t('report/report.loading_report'));
    
    // send ajax requests
    $('.report_header').load(Utils.build_url('dashboard/report_header', id));
    $('.report_main').load(Utils.build_url('report/reports', id));
    
    // clear the dropdown for the next choice
    $('.report_chooser select').val("");
  };

}(ELMO.Views));