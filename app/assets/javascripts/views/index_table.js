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
        // go to the tr's href IF...
        // parent <td> is not .actions_col or .cb_col (to avoid misclick)
        if ($(e.target).closest('td').is(':not(.actions_col, .cb_col)')

            // the parent <tr> is .clickable
            && $(e.currentTarget).is('.clickable')

            // target is not an <input>
            && e.target.tagName != 'INPUT')

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