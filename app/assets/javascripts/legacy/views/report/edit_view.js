// ELMO.Report.EditView
(function (ns, klass) {
  // constructor
  ns.EditView = klass = function (menus, options, controller) {
    const _this = this;

    this.controller = controller;

    // save refs
    this.menus = menus;
    this.options = options;

    // create the container div and dialog
    this.cont = $('div.report_edit_dialog');

    // create the form and disable submit
    this.form = $('form.report_form');
    this.form.submit(() => { return false; });

    // create the panes
    this.panes = [
      this.report_type_pane = new ns.ReportTypeEditPane(this, menus, options),
      this.display_options_pane = new ns.DisplayOptionsEditPane(this, menus, options),
      this.form_selection_pane = new ns.FormSelectionEditPane(this, menus, options),
      this.question_selection_pane = new ns.QuestionSelectionEditPane(this, menus, options),
      this.grouping_pane = new ns.GroupingEditPane(this, menus, options),
      this.field_pane = new ns.FieldsEditPane(this, menus, options),
    ];

    // pane pointer
    this.current_pane_idx = 0;

    // get buttons and hook up click events
    this.cancel_handler = function () { _this.cancel(); return false; };
    this.prev_handler = function () { _this.change_pane(-1); return false; };
    this.next_handler = function () { _this.change_pane(1); return false; };
    this.run_handler = function () { _this.run(); return false; };

    this.buttons = {
      cancel: this.form.find('button.close'),
      prev: this.form.find('button.prev'),
      next: this.form.find('button.next'),
      run: this.form.find('button.run'),
    };
  };

  klass.prototype.show = function (report, idx) {
    const _this = this;

    // save ref to report
    this.report = report;

    // update panes
    const enabled = this.enabled_panes();
    for (let i = 0; i < this.panes.length; i++) {
      if (enabled[this.panes[i].id]) {
        this.panes[i].update(report, true);
      }
    }

    // show the modal and the appropriate pane, disable esc for new modal
    $('#report-edit-modal').modal({ show: true, keyboard: false });

    this.show_pane(idx);

    if (!this.report.new_record) {
      this.esc_handler = function (e) { if (e.key === 'Escape') _this.cancel(); };
      $(document).bind('keyup', this.esc_handler);
    }
  };

  klass.prototype.show_pane = function (idx) {
    const { report } = this;

    // hide current pane
    this.panes[this.current_pane_idx].hide();

    // show new pane and store ref
    this.panes[idx].show();
    this.current_pane_idx = idx;

    // show/hide prev/next/run
    this.update_buttons();

    // create title based on if new report or editing report
    const title = report.new_record ? I18n.t('page_titles.reports.new') : I18n.t('page_titles.reports.edit');

    // update title of modal
    $('.modal-title').html(`${title}: ${I18n.t(`report/report.${this.panes[idx].id}`)}`);
  };

  // go to the next/previous pane
  klass.prototype.change_pane = function (step) {
    // get the idx of the next pane to show
    const next_idx = this.next_pane(step);

    // show it unless it's null
    if (next_idx != null) this.show_pane(next_idx);
  };

  // gets the idx of the next active pane in the given direction
  // returns null if there is none
  klass.prototype.next_pane = function (step) {
    // figure out the next index (don't show disabled panes)
    let idx = this.current_pane_idx;
    const ep = this.enabled_panes(this.report);

    // keep looping until we run past the end of the array or we hit an enabled pane
    do { idx += step; } while (idx >= 0 && idx < this.panes.length && !ep[this.panes[idx].id]);

    // if we went past the end, return null. else return the idx
    return (idx < 0 || idx >= this.panes.length) ? null : idx;
  };

  klass.prototype.run = function () {
    const self = this;
    // tell panes to update model, and let them know if they're currently enabled or not
    const enabled = self.enabled_panes();
    $(self.panes).each(function () {
      this.extract(enabled[this.id]);
    });

    // show/clear validation errors
    this.pane_do('before_validation');

    // validate
    const is_valid = this.report.validate();

    // show/clear validation errors
    this.pane_do('show_validation_errors');

    // send to controller if valid
    if (is_valid) {
      this.controller.update_and_run_report(this.report);
      this.hide();

    // else show the first pane that has errors
    } else {
      for (let i = 0; i < this.panes.length; i++) {
        if (this.panes[i].has_errors) {
          this.show_pane(i);
          return;
        }
      }
    }
  };

  klass.prototype.cancel = function () {
    // unregister keyup event
    $(document).unbind('keyup', this.esc_handler);

    // notify controller
    this.controller.edit_cancelled();
  };

  klass.prototype.hide = function () {
    $('#report-edit-modal').modal('hide');
  };

  // applies a given function to all panes
  klass.prototype.pane_do = function (func_name) {
    for (let i = 0; i < this.panes.length; i++) {
      if (this.panes[i][func_name]) {
        this.panes[i][func_name](Array.prototype.slice.call(arguments, 1));
      }
    }
  };

  klass.prototype.update_buttons = function () {
    this.setButtonEnabled('cancel', true);

    // these buttons should appear if there is another pane in the appropriate direction
    this.setButtonEnabled('prev', this.next_pane(-1) != null);
    this.setButtonEnabled('next', this.next_pane(1) != null);

    // run button should appear if report has already run or if this is the last pane
    this.setButtonEnabled('run', !this.report.new_record || this.next_pane(1) == null);
  };

  klass.prototype.setButtonEnabled = function (name, enable) {
    const button = this.buttons[name];
    const handler = this[`${name}_handler`];
    button.css('cursor', enable ? '' : 'default');

    button.unbind('click');

    if (enable) {
      button.on('click', handler);
      button.show();
      button.removeAttr('disabled');
      if (name === 'run') {
        button.removeClass('btn-secondary');
        button.addClass('btn-primary');
      }
    } else {
      button.on('click', () => { return false; });
      button.attr('disabled', true);
      if (name === 'run') {
        button.addClass('btn-secondary');
        button.removeClass('btn-primary');
      }
    }

    // hide the next button if last pane
    if (name === 'next' && !enable) button.hide();
  };

  klass.prototype.broadcast_change = function (src) {
    // update panes if requested
    for (let i = 0; i < this.panes.length; i++) {
      if (this.panes[i].attribs_to_watch && this.panes[i].attribs_to_watch[src]) {
        this.panes[i].update(this.report, false);
      }
    }
  };

  // returns a hash indicating which panes should be enabled based on the given report
  klass.prototype.enabled_panes = function (report) {
    if (!report) report = this.report;
    return {
      report_type: true,
      display_options: true,
      form_selection: report.attribs.type !== 'Report::StandardFormReport',
      question_selection: report.attribs.type === 'Report::TallyReport' && report.attribs.tally_type === 'Answer',
      grouping: report.attribs.type === 'Report::TallyReport' && report.attribs.tally_type === 'Response',
      fields: report.attribs.type === 'Report::ListReport',
    };
  };
}(ELMO.Report));
