// ELMO.Report.EditView
(function(ns, klass) {
  
  // constructor
  ns.EditView = klass = function(menus, options, controller) {
    var _this = this;
    
    this.controller = controller;
    
    // save refs
    this.menus = menus;
    this.options = options;
    
    // create the container div and dialog
    this.cont = $("<div>").addClass("report_edit_dialog");
    this.dialog = new ELMO.Dialog(this.cont, {dont_show: true});

    // create the form
    this.form = $("<form>");
    this.cont.append(this.form);

    // create the panes
    this.panes = [
      new ns.ReportTypeEditPane(menus),
      new ns.DisplayOptionsEditPane(menus, options),
      //new ns.FormSelectionEditPane(menus),
      new ns.QuestionSelectionEditPane(menus),
      //new ns.FiltersEditPane(menus),
      new ns.ReportTitleEditPane(menus)
    ];
    
    // pane pointer
    this.current_pane_idx = 0;
    
    // add panes to form
    for (var i = 0; i < this.panes.length; i++)
      this.form.append(this.panes[i].cont);
      
    // add buttons
    var button_div = $("<div>").addClass("buttons");
    this.buttons = {
      cancel: $("<a>").attr("href", "#").text("Cancel").click(function() { _this.cancel(); return false; }).appendTo(button_div),
      prev: $("<a>").attr("href", "#").text("<  Previous").click(function() { _this.change_pane(-1); return false; }).appendTo(button_div),
      next: $("<a>").attr("href", "#").text("Next  >").click(function() { _this.change_pane(1); return false; }).appendTo(button_div),
      run: $("<a>").attr("href", "#").text("Run").click(function() { _this.run(); return false; }).appendTo(button_div)
    }
    this.cont.append(button_div);
  }
  
  klass.prototype.show = function(report, idx) {
    // save ref to report
    this.report = report;
    
    // update panes
    for (var i = 0; i < this.panes.length; i++)
      this.panes[i].update(report);
    
    // show the dialog and the appropriate pane
    this.dialog.show();
    this.show_pane(idx);
    
    // hookup esc key
    var _this = this;
    this.esc_handler = function(e){ if (e.keyCode === 27) _this.cancel(); };
    $(document).bind("keyup", this.esc_handler);
  }
  
  klass.prototype.show_pane = function(idx) {
    // hide current pane
    this.panes[this.current_pane_idx].hide();
    
    // show new pane and store ref
    this.panes[idx].show();
    this.current_pane_idx = idx;
    
    // show/hide prev/next/run
    this.show_hide_buttons();
  }
  
  // go to the next/previous pane
  klass.prototype.change_pane = function(step) {
    this.show_pane(Math.max(0, Math.min(this.panes.length - 1, this.current_pane_idx + step)));
  }
  
  klass.prototype.run = function() {
    // tell panes to update model
    this.pane_do("extract");
    
    // validate
    var is_valid = this.report.validate();

    // show/clear validation errors
    this.pane_do("show_validation_errors");
    
    // send to controller if valid
    if (is_valid) 
      this.controller.run_report(this.report);

    // else show the first pane that has errors
    else
      for (var i = 0; i < this.panes.length; i++)
        if (this.panes[i].has_errors) {
          this.show_pane(i);
          return;
        }
  }
  
  klass.prototype.cancel = function() {
    this.dialog.hide();
    
    // unregister keyup event
    $(document).unbind("keyup", this.esc_handler);
  }
  
  klass.prototype.show_hide_buttons = function() {
    this.buttons.prev[this.current_pane_idx > 0 ? "show" : "hide"]();
    this.buttons.next[this.current_pane_idx < this.panes.length - 1 ? "show" : "hide"]();
    this.buttons.run[this.report.has_run() || this.current_pane_idx == this.panes.length - 1 ? "show" : "hide"]();
  }
  
  klass.prototype.hide = function() {
    this.dialog.hide();
  }
  
  klass.prototype.pane_do = function(func_name) {
    for (var i = 0; i < this.panes.length; i++)
      if (this.panes[i][func_name]) this.panes[i][func_name](Array.prototype.slice.call(arguments, 1));
  } 
  
}(ELMO.Report));