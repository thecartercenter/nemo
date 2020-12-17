// Handles the report output and edit modal
ELMO.Views.ReportView = class ReportView extends ELMO.Views.ApplicationView {
  get el() { return '.report-output-and-modal'; }

  initialize(data) {
    this.embeddedMode = data.embedded_mode;

    // create supporting models unless in read only mode
    if (!this.embeddedMode) {
      this.options = data.options;
      this.menus = {
        attrib: new ELMO.Report.AttribMenu(this.options.attribs),
        form: new ELMO.Report.FormMenu(this.options.forms),
        calc_type: new ELMO.Report.CalcTypeMenu(this.options.calculation_types),
        question: new ELMO.Report.QuestionMenu(this.options.questions),
        option_set: new ELMO.Report.OptionSetMenu(this.options.option_sets),
      };
    }

    this.report = new ELMO.Report.Report(data.report, this.menus);

    if (!this.embeddedMode) {
      this.report.prepare();
      this.editView = new ELMO.Report.EditView(this.menus, this.options, this);
    }

    if (this.report.new_record) {
      this.showModal(0);
    } else if (data.edit_mode) {
      this.showModal(1);
    }

    this.displayReport();

    // Pass a reference to self up the chain so that the parent view can open the edit modal.
    this.$el.trigger('report:load', [this]);
  }

  isEmpty() {
    return this.report.has_errors() || this.report.attribs.empty;
  }

  displayReport() {
    if (!this.embeddedMode) {
      ELMO.app.set_title(`${I18n.t('activerecord.models.report/report.one')}: ${this.report.attribs.name}`);
    }
    this.render();
  }

  render() {
    $('.report-info').empty();

    if (this.report.attribs.error) {
      this.showError(this.report.attribs.error);
    } else if (this.report.attribs.empty) {
      $('.report-body').html(I18n.t('report/report.no_match'));
    } else {
      $('<div>').append(`${I18n.t('report/report.generated_at')} ${this.report.attribs.generated_at}`)
        .appendTo($('.report-info'));

      if (this.report.attribs.type === 'Report::StandardFormReport') {
        this.display = new ELMO.Report.FormSummaryDisplay(this.report);
      } else if (this.report.attribs.display_type === 'bar_chart') {
        this.display = new ELMO.Report.BarChartDisplay(this.report);
      } else {
        this.display = new ELMO.Report.TableDisplay(this.report);
      }

      this.display.render();
    }
  }

  showModal(idx) {
    $('.report-links, .report-output').hide();
    this.editView.show(this.report.clone(), idx);
  }

  handleEditCancelled() {
    // if report is new, go back to report index
    if (this.report.new_record) {
      ELMO.app.loading(true);
      window.location.href = ELMO.app.url_builder.build('reports');
    } else this.restoreView();
  }

  // Saves the report to the server and runs it.
  saveAndRedisplay(report) {
    ELMO.app.loading(true);

    const toSerialize = {};
    toSerialize.report = report.to_hash();
    if (report.attribs.id) {
      toSerialize.id = report.attribs.id;
    }
    toSerialize._method = report.attribs.new_record ? 'post' : 'put';
    const url = ELMO.app.url_builder.build('reports', report.attribs.new_record ? '' : report.attribs.id);

    $.ajax({
      type: 'POST',
      url,
      data: $.param(toSerialize),
      success: (report.attribs.new_record ? this.handleCreateSuccess : this.handleUpdateSuccess).bind(this),
      error: this.handleRunError.bind(this),
    });
  }

  handleCreateSuccess(data) {
    // redirect to the show action so that links, etc., will work
    ELMO.app.loading(true);
    window.location.href = data.redirect_url;
  }

  handleUpdateSuccess(data) {
    this.restoreView();
    $('.report-output-and-modal').html(data);
    ELMO.app.loading(false);
  }

  handleRunError(jqxhr, status, error) {
    if (ELMO.unloading) {
      return;
    }
    this.restoreView();
    this.showError(I18n.t(`layout.${error === '' ? 'server_contact_error' : 'system_error'}`));
  }

  restoreView() {
    ELMO.app.loading(false);
    if (this.editView) {
      this.editView.hide();
    }
    $('.report-links, .report-output').show();
  }

  showError(msg) {
    $('.report-info').text(`${I18n.t('common.error.one')}: ${msg}`);
  }
};
