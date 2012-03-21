// setup minute reloading of page
$(document).ready(function() { 
  setInterval(function() { $('#blocks').load('/', 'auto=1', function(response, status) {check_login_required(response)}); }, 60000); 
});
