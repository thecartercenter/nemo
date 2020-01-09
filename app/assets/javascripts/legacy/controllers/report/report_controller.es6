// ELMO.Report.ReportController
(function (ns, klass) {
  // constructor
  ns.ReportController = klass = function (init_data) {
    this.embedded_mode = init_data.embedded_mode;
    this.init_data = init_data;

    // create supporting models unless in read only mode
    if (!init_data.read_only) {
      this.options = init_data.options;
      this.menus = {
        attrib: new ns.AttribMenu(this.options.attribs),
        form: new ns.FormMenu(this.options.forms),
        calc_type: new ns.CalcTypeMenu(this.options.calculation_types),
        question: new ns.QuestionMenu(this.options.questions),
        option_set: new ns.OptionSetMenu(this.options.option_sets),
      };
    }

    this.report_in_db = new ns.Report(init_data.report, this.menus);

    if (!init_data.read_only) this.report_in_db.prepare();

    // create copy of report to be referenced each run
    this.report_last_run = this.report_in_db.clone();

    // create report view
    this.report_view = new ns.ReportView(this, this.report_in_db);

    // create edit view if applicable
    if (!init_data.read_only) this.edit_view = new ns.EditView(this.menus, this.options, this);

    // if is new record, show dialog first page
    if (this.report_in_db.new_record) this.show_edit_view(0);

    // if in edit mode, show edit dialog second page, since report type is not editable
    if (init_data.edit_mode) this.show_edit_view(1);

    if (this.report_last_run.populated) this.display_report(this.report_last_run);
  };

  klass.prototype.show_edit_view = function (idx) {
    $('.report_links, .report_main').hide();
    this.edit_view.show(this.report_last_run.clone(), idx);
  };

  // Does not update, just runs.
  klass.prototype.run_report = function () {
    if (!this.embedded_mode) ELMO.app.loading(true);

    const promise = $.Deferred();

    const url = ELMO.app.url_builder.build('reports', this.report_in_db.attribs.id, 'data');
    (function (_this) {
      $.ajax({
        type: 'GET',
        url,
        success(d, s, j) {
          promise.resolve();
          _this.run_success(d, s, j);
        },
        error(j, s, e) { _this.run_error(j, s, e); },
      });
    }(this));

    return promise;
  };

  // Updates the report and runs it.
  klass.prototype.update_and_run_report = function (report) {
    ELMO.app.loading(true);

    // get hash from report
    const to_serialize = {};
    to_serialize.report = report.to_hash();
    if (report.attribs.id) to_serialize.id = report.attribs.id;

    // comply with REST stuff
    to_serialize._method = report.attribs.new_record ? 'post' : 'put';
    const url = ELMO.app.url_builder.build('reports', report.attribs.new_record ? '' : report.attribs.id);

    // send ajax (use currying for event handlers)
    (function (_this) {
      $.ajax({
        type: 'POST',
        url,
        data: $.param(to_serialize),
        success(d, s, j) { _this.run_success(d, s, j); },
        error(j, s, e) { _this.run_error(j, s, e); },
      });
    }(this));
  };

  klass.prototype.run_success = function (data, status, jqxhr) {
    // if the 'just created' flag is set, redirect to the show action so that links, etc., will work
    if (data.report.just_created) {
      ELMO.app.loading(true);
      window.location.href = ELMO.app.url_builder.build('reports', data.report.id);

    // otherwise we can process the updated report object
    } else {
      this.restore_view();
      this.report_last_run = new ns.Report(data.report, this.menus);
      if (!this.init_data.read_only) this.report_last_run.prepare();
      this.display_report(this.report_last_run);
    }
  };

  klass.prototype.run_error = function (jqxhr, status, error) {
    this.restore_view();
    // show error
    const msg = I18n.t(`layout.${error == '' ? 'server_contact_error' : 'system_error'}`);
    this.report_view.show_error(msg);
  };

  klass.prototype.edit_cancelled = function () {
    // if report is new, go back to report index
    if (this.report_in_db.new_record) {
      ELMO.app.loading(true);
      window.location.href = ELMO.app.url_builder.build('reports');
    // else restore the view
    } else if (!this.report_last_run.populated) {
      const self = this;
      if (this.edit_view) this.edit_view.hide();
      this.run_report().then(() => { self.restore_view(); });
    } else this.restore_view();
  };

  klass.prototype.display_report = function (report) {
    // update the report view
    this.report_view.update(report);

    // show/hide the export link if there is no data or an error
    $('a.export-link')[report.has_errors() || report.attribs.empty ? 'hide' : 'show']();
  };

  klass.prototype.restore_view = function () {
    // hide load ind
    ELMO.app.loading(false);

    if (this.edit_view) this.edit_view.hide();

    // show links and body
    $('.report_links, .report_main').show();
  };

  // refreshes the report view
  klass.prototype.refresh_view = function () {
    this.display_report(this.report_last_run);
  };
}(ELMO.Report));
