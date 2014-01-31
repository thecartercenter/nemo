// ELMO.SearchForm
//
// Models a form for entering a search query.
(function(ns, klass) {

  // constructor
  ns.SearchForm = klass = function() {

    // hookup the clear button to redirect to just the index path with no params
    $("form.search_form input#clear_button").click(function() {
      window.location.href = window.location.href.split('?')[0];
    });

    // setup the search dialog
    $('div.search_footer a').on('click', function(e){
      $("div.search_help").dialog({
        dialogClass: "no-close search_help_modal",
        buttons: [{text: I18n.t('common.ok'), click: function() { $(this).dialog('close'); }}],
        modal: true,
        autoOpen: true,
        width: 800,
        height: 600
      });
      e.preventDefault();
    });
  }

})(ELMO);