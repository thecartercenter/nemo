// Marks elements as having been added automatically (cloned into the form),
// so that we can destroy them automatically later without fear.
var CLONE_MARKER = "CLONE_MARKER";

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
    this.$('#export-dropdown').dropdown();
    new Clipboard('#copy-btn-api_url');
    this.exportWarningThreshold = options.exportWarningThreshold;
    this.exportErrorThreshold = options.exportErrorThreshold;
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

    // Reset defaults in case the modal is shown several times.
    $('#export-count-warning').hide();
    $('#export-count-error').hide();
    $("input[type=submit]").prop("disabled", false);

    // Calculate how many responses will actually be exported.
    let responsesForm = $('.index-table-wrapper form');
    let checked = responsesForm.find('input.batch_op:checked');
    let selectAll = responsesForm.find('input[name=select_all_pages]');
    let shouldExportAll = checked.length === 0 || selectAll.val();
    let exportCount = shouldExportAll ? $('.index-table-wrapper').data('entries') : checked.length;
    $('#export-options-summary').text(I18n.t('response.export_options.summary', { count: exportCount }));

    // Toggle elements as needed.
    if (exportCount >= this.exportErrorThreshold) {
      $('#export-count-error').show();
      $("input[type=submit]").prop("disabled", true);
    } else if (exportCount >= this.exportWarningThreshold) {
      $('#export-count-warning').show();
    }

    // Save the user's selection to the export options,
    // ensuring we wipe the slate clean first in case they open/close the modal multiple times in a row.
    let exportOptionsForm = $('#new_response_csv_export_options');
    exportOptionsForm.find(`[data-${CLONE_MARKER}]`).remove();
    exportOptionsForm.append(checked.clone().map(this.hideAndTrackElement));
    exportOptionsForm.append(selectAll.clone().map(this.hideAndTrackElement));

    $('#export-csv-modal').modal('show');
  }

  hideAndTrackElement(index, el) {
    el.setAttribute("type", "hidden");
    el.setAttribute(`data-${CLONE_MARKER}`, true);
    return el;
  }

  showExportODataModal(event) {
    event.preventDefault();
    this.$('#export-odata-modal').modal('show');
  }

  selectApiUrl() {
    this.$('#copy-value-api_url').selectText();
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
        this.$(`#${id}`).effect('highlight', {}, 1000);
      }
    });
  }

  // Gets IDs of each row in index table
  getIds() {
    return this.$('.index_table_body tr').map((index, row) => row.id).toArray();
  }
};
