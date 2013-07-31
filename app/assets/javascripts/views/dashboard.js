// ELMO.Views.Dashboard
//
// View model for the Dashboard
(function(ns, klass) {
  
  // constructor
  ns.Dashboard = klass = function(params) { var self = this;
    self.params = params;
    
    self.map_view = new ELMO.Views.DashboardMap(self.params.map);
    self.report_view = new ELMO.Views.DashboardReport(self.params.report);
  };
  
}(ELMO.Views));