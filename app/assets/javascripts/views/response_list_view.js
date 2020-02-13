/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// Handles exports and polling for new responses.
ELMO.Views.ResponseListView = class ResponseListView extends ELMO.Views.ApplicationView {
  get events() {
    return {
      'click #export-link': 'showExportModal',
    };
  }

  initialize(options) {
    this.reloadCount = 0;
    if (options.refreshInterval > 0) {
      setInterval(this.fetch.bind(this), options.refreshInterval);
    }
    if (options.showReloadCount) {
      return $('<span id="reload-count"> | Reloads: 0</span>').appendTo($('#footer'));
    }
  }

  showExportModal(event) {
    event.preventDefault();
    this.$('#export-modal').modal('show');
  }

  fetch() {
    this.oldIds = this.getIds();
    let url = Utils.add_url_param(window.location.href, 'auto=1');

    const batchView = ELMO.batch_actions_views.response;
    if (batchView) { // May be nil if no objects.
      batchView.get_selected_items().each(function () {
        return url = Utils.add_url_param(url, `sel[]=${$(this).data('response-id')}`);
      });
      if (batchView.select_all_pages_field.val()) {
        url = Utils.add_url_param(url, 'select_all_pages=1');
      }
    }

    ELMO.app.loading(true);
    return $.ajax({ url, method: 'get', success: this.update.bind(this) });
  }

  update(data) {
    ELMO.app.loading(false);
    $('#index_table').replaceWith(data);
    this.reloadCount += 1;
    $('#reload-count').html(` | Reloads: ${this.reloadCount}`);

    ELMO.batch_actions_views.response.update_links();

    // Highlight any new rows.
    return this.getIds().forEach((id) => {
      if (this.oldIds.indexOf(id) === -1) { return this.$(`#${id}`).effect('highlight', {}, 1000); }
    });
  }

  // Gets IDs of each row in index table
  getIds() {
    const ids = [];
    this.$('.index_table_body tr').each(function () { return ids.push(this.id); });
    return ids;
  }
};
