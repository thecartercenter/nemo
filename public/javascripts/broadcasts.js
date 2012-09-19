function broadcast_medium_changed() {
  var select = $('#broadcast_medium')[0];
  var sms_possible = select.options[select.selectedIndex].value != "email_only";

  // hide/show char limit and subject
  if (sms_possible) {
    $('#char_limit').show();
    $('div#which_phone').show();
    broadcast_update_char_limit();
    $('div#subject').hide();
  } else {
    $('div#which_phone').hide();
    $('#char_limit').hide();
    $('div#subject').show();
  }
}

function broadcast_update_char_limit() {
  if ($('#char_limit').is(":visible")) {
    var diff = 140 - $('#broadcast_body').val().length;
    $('#char_limit').text(Math.abs(diff) + " characters " + (diff >= 0 ? "remaining" : "too many"));
    $('#char_limit').css("color", diff >= 0 ? "black" : "#d02000");
  }
}

$(document).ready(function() { $("#broadcast_medium").change(broadcast_medium_changed); broadcast_medium_changed(); })