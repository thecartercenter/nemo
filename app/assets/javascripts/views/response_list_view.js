// Handles exports and polling for new responses.
ELMO.Views.ResponseListView = class ResponseListView extends ELMO.Views.ApplicationView {
  get events() {
    return {
      'click #export-csv-link': 'showExportCsvModal',
      'click #export-odata-link': 'showExportODataModal',
      'click #copy-value-api_url': 'selectApiUrl',
    };
  }

  initialize(options) {
    $('#export-dropdown').dropdown();
    new Clipboard('#copy-btn-api_url');
    this.reloadCount = 0;
    if (options.refreshInterval > 0) {
      setInterval(this.fetch.bind(this), options.refreshInterval);
    }
    if (options.showReloadCount) {
      $('<span id="reload-count"> | Reloads: 0</span>').appendTo($('#footer'));
    }
  }

  showExportCsvModal(event) {
    event.preventDefault();
    $('#export-csv-modal').modal('show');
  }

  showExportODataModal(event) {
    event.preventDefault();
    $('#export-odata-modal').modal('show');
  }

  selectApiUrl() {
    $('#copy-value-api_url').selectText();
  }

  fetch() {
    this.oldIds = this.getIds();
    let url = Utils.add_url_param(window.location.href, 'auto=1');

    const batchView = ELMO.batch_actions_views.response;
    if (batchView) { // May be nil if no objects.
      batchView.get_selected_items().each(function () {
        url = Utils.add_url_param(url, `sel[]=${$(this).data('response-id')}`);
      });
      if (batchView.select_all_pages_field.val()) {
        url = Utils.add_url_param(url, 'select_all_pages=1');
      }
    }

    ELMO.app.loading(true);
    $.ajax({ url, method: 'get', success: this.update.bind(this) });
  }

  update(data) {
    ELMO.app.loading(false);
    $('.index-table-wrapper').replaceWith(data);
    this.reloadCount += 1;
    $('#reload-count').html(` | Reloads: ${this.reloadCount}`);

    ELMO.batch_actions_views.response.update_links();

    // Highlight any new rows.
    this.getIds().forEach((id) => {
      if (this.oldIds.indexOf(id) === -1) {
        $(`#${id}`).effect('highlight', {}, 1000);
      }
    });
  }

  // Gets IDs of each row in index table
  getIds() {
    return $('.index_table_body tr').map((index, row) => row.id).toArray();
  }
};
