// ELMO.Settings
//
// Models the settings page.
(function(ns, klass) {

  // constructor
  ns.Settings = klass = function(params) {
    // hookup 'select all' link to select the text in the pre
    $("form.setting_form #tableau_sql .form_field_control a").click(function(e) { 
      $("form.setting_form #tableau_sql .form_field_control pre").selectText();
      return false;
    });
  }
  
})(ELMO);

$(document).ready(function(){ new ELMO.Settings(); });