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
    
    // send ajax request
    $.ajax({
      url: Utils.build_url('report/reports', id),
      method: 'GET',
      success: function(data) { $('.report_main').html(data); },
      error: function() { $('.report_main').html(I18n.t('layout.server_contact_error')); }
    });
  };

}(ELMO.Views));