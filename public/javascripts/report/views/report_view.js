// ELMO.Report.ReportView
(function(ns, klass) {
  
  // constructor
  ns.ReportView = klass = function(controller, report) {
    // save refs
    this.controller = controller;
    this.report = report;
    
    // show title
    this.show_title();
    
    // show links
    this.create_links();
  }
  
  klass.prototype.update = function(report) {
    this.report = report;
    
    // show the title
    this.show_title();

    // if there was a handled error with the report model, display it
    if (this.report.attribs.errors)
      this.show_error("Error: " + this.report.attribs.errors);
    // else, the run must have been successful, so render it!
    else
      this.render();
  }
  
  klass.prototype.render = function() {
    // if no matching data, show message
    if (this.report.attribs.data.rows.length == 0) {
      $("#report_info").empty();
      $("#report_body").html("No matching data were found.")
    } else {
      // create an appropriate Display class based on the display_type
      switch (this.report.attribs.display_type) {
        case "Table":
          this.display = new ns.TableDisplay(this.report);
          break;
      }
    
      this.display.render();
      //$("#report_body, #report_links").show();
    }
  }
  
  klass.prototype.show_title = function() {
    // update the title
    $("h1#title").text("Report: " + this.report.attribs.name);
  }
  
  klass.prototype.show_loading_indicator = function(yn) {
    $("#report_load_ind img")[yn ? "show" : "hide"]();
  }
  
  klass.prototype.show_error = function(msg) {
    Utils.show_flash({type: "error", msg: msg});
  }

  // add the link elements to the report_links div
  klass.prototype.create_links = function() {
    // create edit link
    var titles = klass.EDIT_LINK_TITLES;
    for (var i = 0; i < titles.length; i++) {
      // curry to preserve link index
      (function(link_idx, _this){
        // create link and append to link div
        var link = $("<a>").attr("id", "edit_link_" + link_idx).attr("href", "#").text(titles[link_idx]).click(function() { _this.controller.show_edit_view(link_idx+1); return false; });
        link.appendTo($("div#report_links"));
      })(i, this);
    }
  }
  
  klass.EDIT_LINK_TITLES = ["Display Options", "Question Choices", "Title"]
  
}(ELMO.Report));