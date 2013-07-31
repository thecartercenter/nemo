// ELMO.Views.DashboardResponseList
//
// View model for the Dashboard response listing
(function(ns, klass) {

  // horizontal cell padding
  var CELL_H_PADDING = 13;
  
  // constructor
  ns.DashboardResponseList = klass = function() { var self = this;
  };

  // adjusts column widths depending on how many there are
  klass.prototype.adjust_columns = function() { var self = this;
    // age and reviewed columns get fixed widths
    var small_w = 75;
    
    // the rest are computed based on size of pane and number of cols
    var num_cols = $('.recent_responses tbody tr:first-child td').length;
    var pane_w = $('.recent_responses').width();
    
    // this is a guess. we set overflow-x to hidden just in case it's a bit off
    var scrollbar_w = 12;
    
    // first set all of them to the wider width, also allow for scrollbar
    set_col_width((pane_w - 2 * small_w) / (num_cols - 2) - scrollbar_w);
    
    // then set the two smaller ones
    set_col_width(small_w, '.age_col');
    set_col_width(small_w, '.reviewed_col');
  };
  
  // sets the width of the table columns. if cls is given, it's added as a suffix to the td selector.
  function set_col_width(width, cls) { var self = this;
    if (!cls) cls = '';
    
    $('.recent_responses td' + cls).width(width);

    // set inner divs to small width due to padding
    // we use an inner div to handle overflow and prevent wrapping
    $('.recent_responses td' + cls + ' > div').width(width - CELL_H_PADDING);
  };
  
}(ELMO.Views));