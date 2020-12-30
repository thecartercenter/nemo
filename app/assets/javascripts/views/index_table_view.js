/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// Models an index table view as shown on most index pages.
ELMO.Views.IndexTableView = class IndexTableView extends ELMO.Views.ApplicationView {
  get el() { return '.index-table-wrapper'; }

  get events() {
    return {
      'click table.index_table tbody tr': 'row_clicked',
      'mouseover table.index_table tbody tr': 'highlight_partner_row',
      'mouseout table.index_table tbody tr': 'unhighlight_partner_row',
    };
  }

  initialize(params) {
    this.no_whole_row_link = params.no_whole_row_link;

    // flash the modified obj if given
    if (params.modified_obj_id) {
      return $(`#${params.class_name}_${params.modified_obj_id}`).effect('highlight', {}, 1000);
    }
  }

  // hook up whole row link unless told not to
  row_clicked(event) {
    if (this.no_whole_row_link) { return; }

    // go to the tr's href IF...
    // parent <td> is not .action or .cb_col (to avoid misclick)
    if (!$(event.target).closest('td').is(':not(.action, .cb_col)')) { return; }

    // the parent <tr> is .clickable
    if (!$(event.currentTarget).is('.clickable')) { return; }

    // target is not an <input>
    if (event.target.tagName === 'INPUT') { return; }

    return window.location.href = $(event.currentTarget).data('href');
  }

  // add 'hovered' class to partner row if exists
  highlight_partner_row(event) {
    let partner;
    const row = $(event.currentTarget);

    if (row.is('.second_row')) {
      partner = row.prev();
    } else {
      partner = row.next('.second_row');
    }

    if (partner.length > 0) {
      return partner.addClass('hovered');
    }
  }

  // remove 'hovered' class on mouseout
  unhighlight_partner_row(event) {
    return $(event.target).closest('tbody').find('tr.hovered').removeClass('hovered');
  }
};
