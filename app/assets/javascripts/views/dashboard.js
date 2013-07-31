// ELMO.Views.Dashboard
//
// View model for the Dashboard
(function(ns, klass) {
  
  // constructor
  ns.Dashboard = klass = function(params) { var self = this;
    self.params = params;
    
    self.list_view = new ELMO.Views.DashboardResponseList();
    self.map_view = new ELMO.Views.DashboardMap(self.params.map);
    self.report_view = new ELMO.Views.DashboardReport(self.params.report);
    
    // readjust stuff on window resize
    $(window).on('resize', function(){
      self.adjust_pane_sizes();
      self.list_view.adjust_columns();
      
      // clear this timeout in case this is another resize event before it ran out
      clearTimeout(self.resize_done_timeout)
      
      // set a timeout to refresh the report
      self.resize_done_timeout = setTimeout(function(){
        ELMO.app.report_controller.refresh_view();
      }, 1000);
    })
    
    // adjust sizes for the initial load
    self.adjust_pane_sizes();
    self.list_view.adjust_columns();
  };
  
  klass.prototype.adjust_pane_sizes = function() { var self = this;
    // set 3 pane widths/heights depending on container size
    
    // the content window padding and space between columns
    var spacing = 15;
    
    // content window inner dimensions
    var cont_w = $('#content').width() - 4;
    var cont_h = $(window).height() - $('#title').outerHeight(true) - 3 * spacing;
    
    // the height of the h2 elements
    var title_h = $('#content h2').height();
    
    // all widths are the same
    $('.recent_responses, .response_locations, .report_main').width((cont_w - spacing) / 2);
    
    // for left panes height we subtract 2 title heights plus 3 spacings (2 bottom, one top)
    $('.recent_responses, .response_locations').height((cont_h - 2 * title_h - 3 * spacing) / 2);
    
    // for right panes we just subtract one title height and one spacing
    $('.report_main').height(cont_h - title_h - spacing);
  };
  
}(ELMO.Views));