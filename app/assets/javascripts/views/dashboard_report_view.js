// ELMO.Views.DashboardReport
//
// View model for the dashboard report
ELMO.Views.DashboardReportView = class DashboardReportView extends ELMO.Views.ApplicationView {
  get el() {
    return '.report';
  }

  get events() {
    return {
      'change .report-chooser': 'handleReportChange',
      'click .action-link-close': 'handleReportClose',
    };
  }

  handleReportChange(e) {
    const id = $(e.target).val();
    if (id) {
      this.changeReport(id, $(e.target).find('option:selected').text());
    }
  }

  handleReportClose(e) {
    e.preventDefault();
    this.changeReport(null, I18n.t('activerecord.models.report/report.one'));
  }

  changeReport(id, name) {
    this.toggleLoader(true);
    this.$('.report-title-text').html(name);
    this.$('.report-chooser').find('option').attr('selected', false);
    this.$('.report-output-and-modal').empty();
    this.$('.action-link').hide();
    this.$el.load(ELMO.app.url_builder.build(`dashboard/report?id=${id || ''}`));
  }

  toggleLoader(bool) {
    $('.report-pane-header .inline-load-ind img').toggle(bool);
  }
};
