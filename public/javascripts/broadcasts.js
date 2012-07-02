function broadcast_medium_changed() {
  var select = $('#broadcast_medium')[0];
  var sms_possible = select.options[select.selectedIndex].value != "email_only";

  // hide/show char limit and subject
  if (sms_possible) {
    $('#char_limit').show();
    $('#which_phone_row').show();
    broadcast_update_char_limit();
    $('#subject_row').hide();
  } else {
    $('#which_phone_row').hide();
    $('#char_limit').hide();
    $('#subject_row').show();
  }
}

function broadcast_update_char_limit() {
  if ($('#char_limit').is(":visible")) {
    var diff = 140 - $('#broadcast_body').val().length;
    $('#char_limit').text(Math.abs(diff) + " characters " + (diff >= 0 ? "remaining" : "too many"));
    $('#char_limit').css("color", diff >= 0 ? "black" : "#d02000");
  }
}

$.ready(function() { broadcast_medium_changed(); })