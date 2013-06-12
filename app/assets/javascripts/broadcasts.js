function broadcast_medium_changed() { 
  var select = $('#broadcast_medium')[0];
  var selected = select.options[select.selectedIndex].value;
  var sms_possible = selected != "email_only" && selected != "";

  // hide/show char limit and subject
  if (sms_possible) {
    $('#char_limit').show();
    $('div#which_phone').show();
    broadcast_update_char_limit();
    $('div#subject').hide();
    $('.form_field#balance').show();
  } else {
    $('div#which_phone').hide();
    $('#char_limit').hide();
    $('div#subject').show();
    $('.form_field#balance').hide();
  }
}

function broadcast_update_char_limit() {
  if ($('#char_limit').is(":visible")) {
    var diff = 140 - $('#broadcast_body').val().length;
    $('#char_limit').text(Math.abs(diff) + " " + I18n.t("broadcasts.chars." + (diff >= 0 ? "remaining" : "too_many")));
    $('#char_limit').css("color", diff >= 0 ? "black" : "#d02000");
  }
}
