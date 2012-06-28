var LOGIN_PATH = "/user_session/new";

// selects/deselcts all boxes
function batch_select_all() {
  // get checkboxes
  var cbs = batch_get_checkboxes();
  
  // test if all are checked
  var all_checked = batch_all_checked(cbs);

  // check/uncheck boxes
  for (var i = 0; i < cbs.length; i++)
    cbs[i].checked = !all_checked;
    
  // update link
  batch_update_select_all_link(all_checked);
}

// gets all checkboxes in batch_form
function batch_get_checkboxes() {
  return $('#batch_form input[type=checkbox]');
}

// tests if all boxes are checked
function batch_all_checked(cbs) {
  if (typeof(cbs) == "undefined")
    cbs = batch_get_checkboxes();
 
  var all_checked = true;
  for (var i = 0; i < cbs.length; i++)
    if (!cbs[i].checked) {
      all_checked = false;
      break;
    }
  return all_checked;
}

// tests if any boxes are checked
function batch_any_checked(cbs) {
  if (typeof(cbs) == "undefined")
    cbs = batch_get_checkboxes();
 
  var any_checked = false;
  for (var i = 0; i < cbs.length; i++)
    if (cbs[i].checked) {
      any_checked = true;
      break;
    }
  return any_checked;
}

// counts how many boxes are checked
function batch_count_checked(cbs) {
  if (typeof(cbs) == "undefined")
    cbs = batch_get_checkboxes();
 
  var count = 0;
  for (var i = 0; i < cbs.length; i++)
    if (cbs[i].checked)
      count++;
  return count;
}

// updates the select all link to reflect current state of boxes
function batch_update_select_all_link(yn) {
  if (typeof(yn) == "undefined") yn = !batch_all_checked();
  $('#select_all_link').attr("value", (yn ? "S" : "Des") + "elect all");
}

// event handler for when a checkbox is clicked
function batch_cb_changed(cb) {
  // change text of link if all checked
  batch_update_select_all_link(!batch_all_checked());
}

// submits the batch form to the given path
function batch_submit(options) {
  // ensure there is at least one box checked
  var count = batch_count_checked();
  if (count == 0)
    alert("You haven't selected anything.");
  else if (options.confirm == "" || confirm(options.confirm.replace(/###/, count))) {
    // get the form
    var f = $('#batch_form')[0];
    // set the action attrib
    f.action = options.path;
    // submit
    f.submit();
  }
}

// TODO: MOVE TO PROPER FILE
function suggest_login() {
	var name = $('#user_name').val();
	var m, login;
	
	// if it looks like a person's name, suggest f. initial + l. name
	if (m = name.match(/^([a-z][a-z']+) ([a-z'\- ]+)$/i))
		login = m[1].substr(0,1) + m[2].replace(/[^a-z]/ig, "");
	// otherwise just use the whole thing and strip out weird chars
	else
		login = name.replace(/[^a-z0-9\.]/ig, "");
		
	$('#user_login').val(login.substr(0,10).toLowerCase());
}

function logout() {
  // click the logout button
  if ($('#logout_button')) $('#logout_button').click();
}


// checks if the given response text is LOGIN_REQUIRED and redirects appropriately if so
// returns whether a login required message was found
function check_login_required(response) { 
  if (response == "LOGIN_REQUIRED") {
    redirect_to_login(); 
    return true;
  } else
    return false;
}

// redirects to the login page
function redirect_to_login() {
  window.onbeforeunload = null;
  window.location.href = LOGIN_PATH;
}

// UTILITIES
(function (Utils, undefined) {
  Utils.show_flash = function(params) {
    Utils.clear_flash();
    $("#content").prepend($("<div>").addClass(params.type).text(params.msg));
    if (params.hide_after)
      setTimeout(Utils.clear_flash, params.hide_after * 1000);
  }
  
  Utils.clear_success_flash_after_delay = function() {
    setTimeout(function(){$(".success").remove();}, 5000);
  }

  Utils.clear_flash = function(params) {
    $(".success").remove();
    $(".error").remove();
  }
  
  Utils.array_eq = function(a, b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) if (a[i] != b[i]) return false;
    return true;
  }
  
  // runs a jquery ajax request but substitutes a method that checks for session timeout
  Utils.ajax_with_session_timeout_check = function(params) {
    var old_error_func = params.error;
    params.error = function(jqXHR) { check_login_required(jqXHR.responseText) || old_error_func && old_error_func(); };
    $.ajax(params);
  }
  
}(Utils = {}));