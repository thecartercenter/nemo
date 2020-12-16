// ELMO.Report.ReportController
(function (ns, klass) {
  // constructor
  ns.ReportController = klass = function (init_data) {
    this.embedded_mode = init_data.embedded_mode;
    this.init_data = init_data;

    // create supporting models unless in read only mode
    if (!init_data.embedded_mode) {
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

    if (!init_data.embedded_mode) this.report_in_db.prepare();

    // create copy of report to be referenced each run
    this.report_last_run = this.report_in_db.clone();

    // create report view
    this.report_view = new ns.ReportView(this, this.report_in_db);

    // create edit view if applicable
    if (!init_data.embedded_mode) this.edit_view = new ns.EditView(this.menus, this.options, this);

    // if is new record, show dialog first page
    if (this.report_in_db.new_record) this.show_edit_view(0);

    // if in edit mode, show edit dialog second page, since report type is not editable
    if (init_data.edit_mode) this.show_edit_view(1);

    this.display_report(this.report_last_run);
  };

  klass.prototype.show_edit_view = function (idx) {
    $('.report-links, .report-output').hide();
    this.edit_view.show(this.report_last_run.clone(), idx);
  };

  // Updates the report and runs it.
  klass.prototype.submit_report = function (report) {
    ELMO.app.loading(true);

    // get hash from report
    const to_serialize = {};
    to_serialize.report = report.to_hash();
    if (report.attribs.id) to_serialize.id = report.attribs.id;

    // comply with REST stuff
    to_serialize._method = report.attribs.new_record ? 'post' : 'put';
    const url = ELMO.app.url_builder.build('reports', report.attribs.new_record ? '' : report.attribs.id);

    $.ajax({
      type: 'POST',
      url,
      data: $.param(to_serialize),
      success: (report.attribs.new_record ? this.create_success : this.update_success).bind(this),
      error: this.run_error.bind(this),
    });
  };

  klass.prototype.create_success = function(data) {
    // redirect to the show action so that links, etc., will work
    ELMO.app.loading(true);
    window.location.href = data.redirect_url;
  }

  klass.prototype.update_success = function(data) {
    this.restore_view();
    $('.report-output-and-modal').html(data);
    ELMO.app.loading(false);
  }

  klass.prototype.run_error = function (jqxhr, status, error) {
    if (ELMO.unloading) return;
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
    $('.report-links, .report-output').show();
  };

  // refreshes the report view
  klass.prototype.refresh_view = function () {
    this.display_report(this.report_last_run);
  };
}(ELMO.Report));
