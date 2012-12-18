// ELMO.Report.BarChartDisplay < ELMO.Report.Display
(function(ns, klass) {
  
  // constructor
  ns.BarChartDisplay = klass = function(report) {
    this.report = report;
  }

  // inherit
  klass.prototype = new ns.Display();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.Display.prototype;
  
  klass.prototype.render = function() {
    var _this = this;
    var data = this.report.attribs.data;
    var headers = this.report.attribs.headers;

    // set up data
    var g_data = new google.visualization.DataTable();
    
    // add first column (pri_grouping)
    g_data.addColumn('string', 'main');
    
    // make empty series array to hold colors
    var series = [];
    var color_counter = 0;
    
    // add rest of columns (sec_grouping)
    $(headers.col.cells).each(function(idx, ch){
      
      // add the next default color, or gray if ch is blank
      series.push({color: ch.name ? DEFAULT_BAR_COLORS[color_counter++] : NULL_BAR_COLOR});
      
      // add the column header
      g_data.addColumn('number', ch.name || "[Null]");
    })
    
    $(headers.row.cells).each(function(r, rh){
      // build the row
      var row = [rh.name || "[Null]"];

      // add cells to row and add row to obj
      $(headers.col.cells).each(function(c, ch) {
        var val = data.rows[r][c] || 0;
        row.push(val);
      });
      g_data.addRow(row);
    });

    // get whether it's stacked
    var stacked = this.report.attribs.bar_style == "Stacked";
    
    // get space needed for chart elements
    var haxis_space = 50;
    var vaxis_space = this.report.attribs.question_labels == "Code" ? 150 : 300;
    var legend_space = 150;
    
    var cont_height = Math.max(300, headers.row.cells.length * (stacked ? 20 : headers.col.cells.length * 15) + haxis_space);
    var cont_width = $("#content").width() - $("#report_links").width() - 200;
    var options = {
      width: cont_width,
      height: cont_height,
      bar: {groupWidth: "80%"},
      legend: {textStyle: {fontSize: 12}},
      vAxis: {title: headers.row.title, textStyle: {fontSize: 12}},
      hAxis: {title: this.report.aggregation(), textStyle: {fontSize: 12}},
      chartArea: {top: 0, left: vaxis_space, height: cont_height - haxis_space, width: cont_width - legend_space - vaxis_space},
      isStacked: stacked,
      series: series
    };

    var chart = new google.visualization.BarChart($('#report_body')[0]);
    chart.draw(g_data, options);
  }
  
  var DEFAULT_BAR_COLORS = ["Green", "Gold", "DarkOrange", "Red", "Blue", "Indigo", "Bisque", "LightGreen", "Sienna", "LightBlue"];
  var NULL_BAR_COLOR = "Silver";
  
}(ELMO.Report));