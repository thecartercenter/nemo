// ELMO.Views.StandardImportForm
//
// View model for importing standard objects.
(function(ns, klass) {

  // constructor
  ns.StandardImportForm = klass = function(params) { var self = this;
    self.params = params;

    // setup the link
    $('a.import_standard').click(function(){ self.show_dialog(); return false; });
  };

  klass.prototype.show_dialog = function() { var self = this;
    $('div.importable div.modal_error').hide();

    // create the dialog
    $("div.importable").dialog({
      dialogClass: "no-close standard_import_modal",
      buttons: [
        {text: I18n.t('common.cancel'), click: function() { $(this).dialog('close'); }},
        {text: I18n.t('standard.import'), click: function() { self.do_import(); }}
      ],
      modal: true,
      autoOpen: true,
      width: 500,
      height: 300
    });

  };

  klass.prototype.do_import = function() { var self = this;
    if ($('div.importable form input:checked').length == 0)
      $('div.importable div.modal_error').show();
    else
      $('div.importable form').submit();
  };
  
})(ELMO.Views);
