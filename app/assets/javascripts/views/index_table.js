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
        // but don't do it with td.actions_col or td.actions_col > div to avoid misclick
        if ($(e.target).is('div:not(.actions_col > div), td:not(.actions_col)'))
          window.location.href = $(e.currentTarget).data('href'); 
      });
  }

})(ELMO.Views);