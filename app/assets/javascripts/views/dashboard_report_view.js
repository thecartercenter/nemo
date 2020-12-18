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
    };
  }

  handleReportChange(e) {
    const id = $(e.target).val();
    if (id) {
      this.changeReport(id, $(e.target).find('option:selected').text());
    }
  }

  changeReport(id, name) {
    const self = this;

    this.toggleLoader(true);
    this.$('.report-title-text').html(name);
    this.$('.report-output-and-modal').empty();
    this.$('.report-edit-link-container').hide();
    this.$el.load(ELMO.app.url_builder.build(`dashboard/report?id=${id}`), () => {
      self.toggleLoader(false);
    });
  }

  toggleLoader(bool) {
    $('.report-pane-header .inline-load-ind img').toggle(bool);
  }
};
