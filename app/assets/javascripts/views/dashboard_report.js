// ELMO.Views.DashboardReport
//
// View model for the dashboard report
(function(ns, klass) {
  
  // constructor
  ns.DashboardReport = klass = function(params) { var self = this;
    self.params = params;
    
    // hookup the form change event
    $('form.report_chooser').on('change', function(e){ 
      var report_id = $(e.target).val();
      if (report_id) self.load_report(report_id);
    });
  };
  
  klass.prototype.load_report = function(id) { var self = this;
    // show loading message
    $('.report_pane h2').html(I18n.t('report/report.loading_report'));
    $('.report_main').empty();
    
    // send ajax request
    $('.report_pane').load(Utils.build_url('dashboard/report_pane', id), function(){
      // fix pane sizes again after load is done
      self.params.dashboard.adjust_pane_sizes();
    });
    
    // clear the dropdown for the next choice
    $('.report_chooser select').val("");
  };

}(ELMO.Views));