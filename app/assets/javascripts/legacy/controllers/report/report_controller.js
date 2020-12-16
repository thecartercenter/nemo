// ELMO.Report.ReportController
(function (ns, klass) {
  // constructor
  ns.ReportController = klass = function (init_data) {
    var self = this;
    $('.top-action-links a.edit-link').click(() => { self.show_edit_view(1); return false; });

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

    this.report = new ns.Report(init_data.report, this.menus);

    if (!init_data.embedded_mode) this.report.prepare();

    if (!init_data.embedded_mode) {
      this.edit_view = new ns.EditView(this.menus, this.options, this);
    }

    // if is new record, show dialog first page
    if (this.report.new_record) {
      this.show_edit_view(0);
    } else if (init_data.edit_mode) {
      this.show_edit_view(1);
    }

    this.display_report(this.report);
  };

  klass.prototype.show_edit_view = function (idx) {
    $('.report-links, .report-output').hide();
    this.edit_view.show(this.report.clone(), idx);
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
    const msg = I18n.t(`layout.${error == '' ? 'server_contact_error' : 'system_error'}`);
    this.show_error(msg);
  };

  klass.prototype.edit_cancelled = function () {
    // if report is new, go back to report index
    if (this.report.new_record) {
      ELMO.app.loading(true);
      window.location.href = ELMO.app.url_builder.build('reports');
    } else this.restore_view();
  };

  klass.prototype.display_report = function () {
    this.show_title();

    if (this.report.attribs.error) {
      this.show_error(this.report.attribs.error);
    } else {
      this.render();
    }

    // show/hide the export link if there is no data or an error
    $('a.export-link')[this.report.has_errors() || this.report.attribs.empty ? 'hide' : 'show']();
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
    this.display_report(this.report);
  };

  klass.prototype.render = function () {
    // clear out info bar
    $('.report_info').empty();

    // if no matching data, show message
    if (this.report.attribs.empty) {
      $('.report_body').html(I18n.t('report/report.no_match'));
    } else {
      // add the generated date/time to info bar
      $('<div>').append(`${I18n.t('report/report.generated_at')} ${this.report.attribs.generated_at}`).appendTo($('.report_info'));

      // create an appropriate Display class based on the display_type
      if (this.report.attribs.type == 'Report::StandardFormReport') this.display = new ns.FormSummaryDisplay(this.report);

      else if (this.report.attribs.display_type == 'bar_chart') this.display = new ns.BarChartDisplay(this.report);

      else this.display = new ns.TableDisplay(this.report);

      this.display.render();
    }
  };

  // sets page title unless in dashboard
  klass.prototype.show_title = function () {
    if (!this.embedded_mode) ELMO.app.set_title(`${I18n.t('activerecord.models.report/report.one')}: ${this.report.attribs.name}`);
  };

  klass.prototype.show_error = function (msg) {
    $('.report_info').text(`${I18n.t('common.error.one')}: ${msg}`);
  };
}(ELMO.Report));
