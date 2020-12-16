// Handles the outer reports#show template
ELMO.Views.ReportPageView = class ReportView extends ELMO.Views.ApplicationView {
  get el() { return '.report-page'; }

  get events() {
    return {
      'click .top-action-links a.edit-link': 'handleEditClick',
      'report:load': 'handleReportLoad',
    };
  }

  handleReportLoad(e, reportView) {
    this.reportView = reportView;
    this.$('a.export-link').toggle(!this.reportView.isEmpty());
  }

  handleEditClick(e) {
    e.preventDefault();
    this.reportView.showModal(1);
  }
};
