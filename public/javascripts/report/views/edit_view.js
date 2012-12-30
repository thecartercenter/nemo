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
    this.cont = $("div.report_edit_dialog");
    this.dialog = new ELMO.Dialog(this.cont, {dont_show: true});

    // create the form and disable submit
    this.form = $("form.report_form");
    this.form.submit(function(){ return false; });

    // create the panes
    this.panes = [
      this.report_type_pane = new ns.ReportTypeEditPane(this, menus),
      this.display_options_pane = new ns.DisplayOptionsEditPane(this, menus, options),
      this.form_selection_pane = new ns.FormSelectionEditPane(this, menus),
      this.question_selection_pane = new ns.QuestionSelectionEditPane(this, menus),
      this.grouping_pane = new ns.GroupingEditPane(this, menus),
      this.field_pane = new ns.FieldsEditPane(this, menus),
      this.report_title_pane = new ns.ReportTitleEditPane(this, menus)
    ];

    // pane pointer
    this.current_pane_idx = 0;
    
    // get buttons and hook up click events
    this.cancel_handler = function() { _this.cancel(); return false; };
    this.prev_handler = function() { _this.change_pane(-1); return false; };
    this.next_handler = function() { _this.change_pane(1); return false; };
    this.run_handler = function() { _this.run(); return false; };

    this.buttons = {
      cancel: this.form.find("a.cancel"),
      prev: this.form.find("a.prev"),
      next: this.form.find("a.next"),
      run: this.form.find("a.run")
    }
  }
  
  klass.prototype.show = function(report, idx) {
    var _this = this;

    // save ref to report
    this.report = report;
    
    // update panes
    var enabled = this.enabled_panes();
    for (var i = 0; i < this.panes.length; i++)
      if (enabled[this.panes[i].id])
        this.panes[i].update(report, true);
    
    this.show_hide_edit_links(this.report);

    // show the dialog and the appropriate pane
    this.dialog.show();
    this.show_pane(idx);
    
    // hookup esc key
    if (this.report.has_run()) {
      this.esc_handler = function(e){ if (e.keyCode === 27) _this.cancel(); };
      $(document).bind("keyup", this.esc_handler);
    }
  }
  
  klass.prototype.show_pane = function(idx) {
    // hide current pane
    this.panes[this.current_pane_idx].hide();

    // show new pane and store ref
    this.panes[idx].show();
    this.current_pane_idx = idx;
    
    // show/hide prev/next/run
    this.update_buttons();
  }
  
  // go to the next/previous pane
  klass.prototype.change_pane = function(step) {
    // don't be silly
    if (step == -1 && this.current_pane_idx == 0 || step == 1 && this.current_pane_idx == this.panes.length - 1)
      return;
      
    // figure out the next index (don't show disabled panes)
    var idx = this.current_pane_idx;
    var ep = this.enabled_panes(this.report);
    do {
      idx += step;
    } while (!ep[this.panes[idx].id]);
    
    // show the pane
    this.show_pane(idx);
  }
  
  klass.prototype.run = function() { var self = this;
    // tell panes to update model, and let them know if they're currently enabled or not
    var enabled = self.enabled_panes();
    $(self.panes).each(function(){
      this.extract(enabled[this.id]);
    });
    
    // show/clear validation errors
    this.pane_do("before_validation");
    
    // validate
    var is_valid = this.report.validate();

    // show/clear validation errors
    this.pane_do("show_validation_errors");
    
    // send to controller if valid
    if (is_valid) {
      this.controller.run_report(this.report);
      this.dialog.hide();

    // else show the first pane that has errors
    } else {
      for (var i = 0; i < this.panes.length; i++)
        if (this.panes[i].has_errors) {
          this.show_pane(i);
          return;
        }
    }
  }
  
  klass.prototype.cancel = function() {
    this.dialog.hide();
    
    // unregister keyup event
    $(document).unbind("keyup", this.esc_handler);
    
    // notify controller
    this.controller.edit_cancelled();
  }
  
  klass.prototype.hide = function() {
    this.dialog.hide();
  }

  // applies a given function to all panes
  klass.prototype.pane_do = function(func_name) {
    for (var i = 0; i < this.panes.length; i++)
      if (this.panes[i][func_name]) this.panes[i][func_name](Array.prototype.slice.call(arguments, 1));
  } 

  klass.prototype.update_buttons = function() {
    this.enable_button("cancel", true);
    this.enable_button("prev", this.current_pane_idx > 0);
    this.enable_button("next", this.current_pane_idx < this.panes.length - 1);
    this.enable_button("run", this.report.has_run() || this.current_pane_idx == this.panes.length - 1);
  }
  
  klass.prototype.enable_button = function(name, which) {
    var button = this.buttons[name];
    var handler = this[name + "_handler"];
    button.css("color", which ? "" : "#888");
    button.css("cursor", which ? "" : "default");
    button.unbind("click");
    if (which)
      button.bind("click", handler);
    else
      button.bind("click", function() { return false; });
  }

  klass.prototype.broadcast_change = function(src) {
    // update panes if requested
    for (var i = 0; i < this.panes.length; i++)
      if (this.panes[i].attribs_to_watch && this.panes[i].attribs_to_watch[src])
        this.panes[i].update(this.report, false);
        
    this.show_hide_edit_links(this.report);
  }
  
  klass.prototype.show_hide_edit_links = function(report) {
    var ep = this.enabled_panes(report);
    for (var i = 0; i < this.panes.length; i++)
      $("#report_links a#edit_link_" + i)[ep[this.panes[i].id] ? "show" : "hide"]();
  }
  
  // returns a hash indicating which panes should be enabled based on the given report
  klass.prototype.enabled_panes = function(report) {
    if (!report) report = this.report;
    return {
      report_type: true,
      display_options: true,
      form_selection: true,
      question_selection: report.attribs.type == "Report::QuestionAnswerTallyReport",
      grouping: report.attribs.type == "Report::GroupedTallyReport",
      fields: report.attribs.type == "Report::ListReport",
      report_title: true
    }
  }
}(ELMO.Report));