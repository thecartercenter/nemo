// ELMO.Views.DashboardReport
//
// View model for the dashboard report
ELMO.Views.DashboardReportView = class DashboardReportView extends ELMO.Views.ApplicationView {
  get el() {
    return '.report';
  }

  get events() {
    return { 'change .report-chooser': 'handleReportChange' };
  }

  handleReportChange(e) {
    const id = $(e.target).val();
    if (id) {
      this.changeReport(id, $(e.target).find('option:selected').text());
    }
  }

  changeReport(id, name) {
    const self = this;

    $('.report-title-text').html(name);
    $('.report-pane-header .inline-load-ind img').show();
    $('.report-output').empty();
    $('.report-chooser select').val('');
    $('.report-edit-link-container').hide();
    $('.report-output-and-modal').load(ELMO.app.url_builder.build('reports', id), () => self.displayReport());
  }

  displayReport() {
    $('.report-pane-header .inline-load-ind img').hide();
    this.updateEditLink();
  }

  updateEditLink() {
    if (this.report().attribs.user_can_edit) {
      const reportUrl = `${ELMO.app.url_builder.build('reports', this.report().attribs.id)}/edit`;

      $('.report-edit-link-container').show();
      $('.report-edit-link-container a').attr('href', reportUrl);
    } else {
      $('.report-edit-link-container').hide();
      $('.report-edit-link-container a').attr('href', '');
    }
  }

  report() {
    return ELMO.app.report_controller.report_last_run;
  }
};
