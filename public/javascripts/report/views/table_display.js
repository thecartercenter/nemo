// ELMO.Report.TableDisplay < ELMO.Report.Display
(function(ns, klass) {
  
  // constructor
  ns.TableDisplay = klass = function(report) {
    this.report = report;
  }

  // inherit
  klass.prototype = new ns.Display();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.Display.prototype;
  
  klass.prototype.show_totals = function(row_or_col) {
    return true;
  }

  // formats a given fraction as a percentage
  klass.prototype.format_percent = function (frac) {
    return (frac * 100).toFixed(1) + "%";
  }
  
  klass.prototype.render = function() {
    var _this = this;
    var data = this.report.attribs.data;
    var headers = this.report.attribs.headers;
    var tbl = $("<table>");

    // column label row
    if (headers.col) {
      var trow = $("<tr>");
      
      // blank cells for row grouping label and row header, if necessary
      if (headers.row) { $("<th>").appendTo(trow); $("<th>").appendTo(trow); }
     
      // col grouping label
      $("<th>").addClass("col_grouping_label").attr("colspan", headers.col.cells.length).text(headers.col.title).appendTo(trow);
      
      // row total cell
      if (_this.show_totals("row")) $("<th>").appendTo(trow);
      
      tbl.append(trow);
    }
    
    // header row
    if (headers.col.cells.length > 1 || headers.row.cells.length > 1) {
      var trow = $("<tr>");
    
      // blank cells for row grouping label and row header, if necessary
      if (headers.row) { $("<th>").appendTo(trow); $("<th>").appendTo(trow); }
    
      // rest of header cells
      $(headers.col.cells).each(function(idx, ch) {
        $("<th>").addClass("col").text(ch.name || "[Null]").appendTo(trow);
      });

      // row total header
      if (_this.show_totals("row"))
        $("<th>").addClass("row_total").text("Total").appendTo(trow);

      tbl.append(trow);
    }
    
    // create the row grouping label
    var row_grouping_label;
    if (headers.row) {
      var txt = headers.row.title.replace(/\s+/g, "<br/>")
      row_grouping_label = $("<th>").addClass("row_grouping_label").attr("rowspan", headers.row.cells.length);
      row_grouping_label.append($("<div>").html(txt));
    }
  
    // body
    $(headers.row.cells).each(function(r, rh) {
      trow = $("<tr>");
    
      // add the row grouping label if it is defined (also delete it so it doesn't get added again)
      if (row_grouping_label) {
        trow.append(row_grouping_label);
        row_grouping_label = null;
      }
    
      // row header
      if (rh != null) $("<th>").addClass("row").text(rh.name || "[Null]").appendTo(trow);
    
      // row cells
      $(headers.col.cells).each(function(c, ch) {
        // get cell type
        var typ = typeof(data.rows[r][c]);
        
        // get cell value
        var val = data.rows[r][c];
        if (val == null) val = "";
        
        // calculate percentage if necessary
        if (val != "" && _this.report.attribs.percent_type) {
          switch (_this.report.attribs.percent_type) {
            case "overall": val /= data.totals.grand; break;
            case "by_row": val /= data.totals.row[r]; break;
            case "by_column": val /= data.totals.col[c]; break;
          }
          val = _this.format_percent(val);
        }
        $("<td>").text(val).addClass(typ).appendTo(trow);
      });
    
      // row total
      if (_this.show_totals("row")) {
        var val = data.totals.row[r];
        
        // don't display 0s
        if (val == 0) val = "";

        // calculate percentage if necessary
        if (_this.report.attribs.percent_type && val != "") 
          val = _this.format_percent(val / data.totals.grand);
        
        // add the cell
        $("<td>").addClass("row_total").text(val).addClass("number").appendTo(trow);
      }
      
      tbl.append(trow);
    });
  
    // footer
    if (_this.show_totals("col")) {
      trow = $("<tr>");
    
      // blank cells for row grouping label and row header, if necessary
      if (headers.row) { $("<th>").appendTo(trow); }
     
      // row header
      $("<th>").addClass("row").addClass("col_total").text("Total").appendTo(trow);
    
      // row cells
      $(data.totals.col).each(function(c, ct) {
        var val = ct;
        
        // don't display 0s
        if (val == 0) val = "";

        // calculate percentage if necessary
        if (_this.report.attribs.percent_type && val != "")
          val = _this.format_percent(val / data.totals.grand);
        
        // add cell
        $("<td>").addClass("col_total").text(val).addClass("number").appendTo(trow);
      });
    
      // grand total
      if (_this.show_totals("row")) {
        var val = (gt = data.totals.grand) > 0 ? gt : "";
        
        // calculate percentage if necessary
        if (_this.report.attribs.percent_type && val != "") 
          val = _this.format_percent(1);
          
        $("<td>").addClass("row_total").addClass("col_total").text(val).addClass("number").appendTo(trow);
      }

      tbl.append(trow);
    }
    
    // add a row count
    $('#report_info').empty().append($("<div>").attr("id", "row_count").text("Total Rows: " + data.rows.length));
    
    // add the table
    $('#report_body').empty().append(tbl);
  }
  
}(ELMO.Report));