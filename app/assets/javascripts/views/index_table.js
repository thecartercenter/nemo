// ELMO.Views.IndexTable
//
// Models an index table view as shown on most index pages.
(function(ns, klass) {

  // constructor
  ns.IndexTable = klass = function(params) {
    // flash the modified obj if given
    if (params.modified_obj_id)
      $('#' + params.class_name + '_' + params.modified_obj_id).effect("highlight", {}, 1000);

    // hook up whole row link unless told not to
    if (!params.no_whole_row_link)
      $('table.index_table tbody').on('click', 'tr', function(e) {
        // go to the tr's href if the click was on a non-active element
        // but don't do it with td.actions_col or td.cb_col (checkbox column) to avoid misclick
        // also donl't do it unless the tr is .clickable
        if ($(e.target).closest('td').is(':not(.actions_col, .cb_col)') && $(e.currentTarget).is('.clickable'))
          window.location.href = $(e.currentTarget).data('href');
      });

    // add 'hovered' class to partner row if exists
    $('table.index_table tbody').on('mouseover', 'tr', function(e) {
      var row = $(e.currentTarget);

      if (row.is('.second_row'))
        partner = row.prev();
      else
        partner = row.next('.second_row');

      if (partner.length > 0)
        partner.addClass('hovered');
    });

    // remove 'hovered' class on mouseout
    $('table.index_table tbody').on('mouseout', 'tr', function(e) {
      $('table.index_table tbody tr.hovered').removeClass('hovered');
    });

  }

})(ELMO.Views);