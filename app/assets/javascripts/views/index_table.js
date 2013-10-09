// ELMO.Views.IndexTable
//
// Models an index table view as shown on most index pages.
(function(ns, klass) {

  // constructor
  ns.IndexTable = klass = function(params) {
    // flash the modified obj if given
    console.log(params.class_name + '_' + params.modified_obj_id)
    if (params.modified_obj_id)
      $('#' + params.class_name + '_' + params.modified_obj_id).effect("highlight", {}, 1000);
  }

})(ELMO.Views);