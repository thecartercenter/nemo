// ELMO.Views.StandardImportForm
//
// View model for importing standard objects.
(function (ns, klass) {
  // constructor
  ns.StandardImportForm = klass = function (params) {
    const self = this;
    self.params = params;

    // setup the link
    $('a.import_standard').click(() => { self.show_dialog(); return false; });
  };

  klass.prototype.show_dialog = function () {
    const self = this;
    // hide any previous errors
    $('div.importable div.modal_error').hide();
    // only hook up import button if there are items to import
    if (self.params.importable_count > 0) $('button.btn-primary').click(() => { self.do_import(); return false; });

    // show the importables and modal
    $('.importable').show();
    $('#standard-import-form').modal('show');
  };

  klass.prototype.do_import = function () {
    const self = this;
    // show error if nothing selected, otherwise submit form
    if ($('div.importable form input:checked').length == 0) {
      $('div.importable div.modal_error').show();
    } else {
      $('div.importable form').submit();
      $('#standard-import-form').modal('hide');
    }
  };
}(ELMO.Views));
