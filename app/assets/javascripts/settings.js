// ELMO.Settings
//
// Models the settings page.
(function(ns, klass) {

  // constructor
  ns.Settings = klass = function(params) { var self = this;

    // hookup 'select all' link to select the text in the pre
    $("form.setting_form #external_sql .control a").click(function(e) {
      $("form.setting_form #external_sql .control pre").selectText();
      return false;
    });

    // hookup the sms adapter select box to reveal the correct adapter settings
    $("form.setting_form select#setting_outgoing_sms_adapter").on("change", function(){ self.show_adapter_settings(); });
    self.show_adapter_settings();

    // hookup change password links
    $("form.setting_form .adapter_settings a").on("click", function(){
      $(this).hide();
      $(this).closest('.adapter_settings').find(".password_fields").show();
      return false;
    });
  }

  // shows the settings controls for the appropriate adapter
  klass.prototype.show_adapter_settings = function() {
    // first hide all
    $("form.setting_form .adapter_settings").hide();

    // get the current outgoing adapter
    var adapter = $("form.setting_form select#setting_outgoing_sms_adapter").val();

    // then show the appropriate one (if any)
    if (adapter) $("form.setting_form .adapter_settings[data-adapter=" + adapter + "]").show();
  }

})(ELMO);
