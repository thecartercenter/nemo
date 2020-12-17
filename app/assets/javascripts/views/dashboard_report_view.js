// ELMO.Views.DashboardReport
//
// View model for the dashboard report
ELMO.Views.DashboardReportView = class DashboardReportView extends ELMO.Views.ApplicationView {
  get el() {
    return '.right-col';
  }

  get events() {
    return {
      'change .report-chooser': 'handleReportChange',
      'report:load': 'handleReportLoad',
    };
  }

  handleReportChange(e) {
    const id = $(e.target).val();
    if (id) {
      this.changeReport(id, $(e.target).find('option:selected').text());
    }
  }

  handleReportLoad(e, reportView) {
    this.reportView = reportView;
    this.updateEditLink(reportView.report);
  }

  changeReport(id, name) {
    const self = this;

    this.toggleLoader(true);
    $('.report-title-text').html(name);
    $('.report-output').empty();
    $('.report-chooser select').val('');
    $('.report-edit-link-container').hide();
    $('.report-output-and-modal').load(ELMO.app.url_builder.build('reports', id), () => {
      self.toggleLoader(false)
    });
  }

  toggleLoader(bool) {
    $('.report-pane-header .inline-load-ind img').toggle(bool);
  }

  updateEditLink(report) {
    if (report.attribs.user_can_edit) {
      const reportUrl = `${ELMO.app.url_builder.build('reports', report.attribs.id)}/edit`;
      $('.report-edit-link-container').css('display', 'inline-block');
      $('.report-edit-link-container a').attr('href', reportUrl);
    } else {
      $('.report-edit-link-container').hide();
      $('.report-edit-link-container a').attr('href', '');
    }
  }
};
