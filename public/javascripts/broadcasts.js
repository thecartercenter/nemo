function broadcast_medium_changed() {
  var select = $('broadcast_medium');
  var sms = select.options[select.selectedIndex].value != "email";

  // hide/show char limit
  if (sms) {
    $('char_limit').show();
    broadcast_update_char_limit();
  } else
    $('char_limit').hide();

  // show/hide subject
  toggle_table_row('subject_row', !sms);
}

function broadcast_update_char_limit() {
  if ($('char_limit').visible()) {
    var diff = 140 - $('broadcast_body').value.length;
    $('char_limit').innerHTML = Math.abs(diff) + " characters " + (diff >= 0 ? "remaining" : "too many")
    $('char_limit').style.color = diff >= 0 ? "#005882" : "#800000";
  }
}