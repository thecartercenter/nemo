// ELMO.Report.BarChartDisplay < ELMO.Report.Display
(function(ns, klass) {

  // constructor
  ns.BarChartDisplay = klass = function(report) {
    this.report = report;
  }

  var format_header = function(str) {
    return (str || '[Null]').strip_html();
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
      g_data.addColumn('number', format_header(ch.name));
    })

    $(headers.row.cells).each(function(r, rh){
      // build the row
      var row = [format_header(rh.name)];

      // add cells to row and add row to obj
      $(headers.col.cells).each(function(c, ch) {
        var val = data.rows[r][c] || 0;
        row.push(val);
      });
      g_data.addRow(row);
    });

    // get whether it's stacked
    var stacked = this.report.attribs.bar_style == "stacked";

    // get space needed for chart elements
    var haxis_space = 50;
    var vaxis_space = this.report.attribs.question_labels == "code" ? 150 : 300;
    var legend_space = 150;

    var cont_height = Math.max(300, headers.row.cells.length * (stacked ? 20 : headers.col.cells.length * 15) + haxis_space);
    var cont_width = $(".report_main").width() - 20;
    var options = {
      width: cont_width,
      height: cont_height,
      bar: {groupWidth: "80%"},
      legend: {textStyle: {fontSize: 12}},
      vAxis: {title: headers.row.title, textStyle: {fontSize: 12}, titleTextStyle: {fontSize: 14}},
      hAxis: {title: this.report.aggregation(), textStyle: {fontSize: 12}, titleTextStyle: {fontSize: 14}},
      chartArea: {top: 0, left: vaxis_space, height: cont_height - haxis_space, width: cont_width - legend_space - vaxis_space},
      isStacked: stacked,
      series: series,
      tooltip: {isHtml: true, textStyle: {fontSize: 11}}
    };

    var chart = new google.visualization.BarChart($('.report_body')[0]);
    chart.draw(g_data, options);
  }

  var DEFAULT_BAR_COLORS = ["Green", "Gold", "DarkOrange", "Red", "Blue", "Indigo", "Bisque", "LightGreen", "Sienna", "LightBlue"];
  var NULL_BAR_COLOR = "Silver";

}(ELMO.Report));
