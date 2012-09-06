var ELMO = {};
ELMO.LAT_LNG_REGEXP = /^(-?\d+(\.\d+)?)\s*[,;:\s]\s*(-?\d+(\.\d+)?)/

// pads strings to the left
String.prototype.lpad = function(pad_str, length) {
  var str = this;
  while (str.length < length) str = pad_str + str;
  return str;
}
 
// pads strings to the right
String.prototype.rpad = function(pad_str, length) {
  var str = this;
  while (str.length < length) str = str + pad_str;
  return str;
}

// hookup mission dropdown box to submit form
$(document).ready(function(){ $("select#user_current_mission_id").change(function(e){ 
  // show loading indicator
  $(e.target).parents("form").find("div.loading_indicator img").show();
  
  // submit form
  $(e.target).parents("form").submit(); 
}) });