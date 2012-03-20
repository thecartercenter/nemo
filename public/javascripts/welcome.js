// setup minute reloading of page
$(document).ready(function(){ setInterval(function(){ $('#blocks').load('/'); }, 60000); });
