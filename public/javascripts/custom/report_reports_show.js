(function (report, undefined) {
  // === PRIVATE ===

  //var foo = "foo";


  // === PUBLIC ===
  
  // public methods and properties  
  report.data = [];  

  // initializes things
  report.init = function() {
    // hook up buttons
    
    // redraw report
    redraw();
  }
  
  // === PRIVATE ===
  
  // decides whether to contact the server and redraws the report
  // save - whether the changes should be saved or only displayed
  function run(save) {
    // if change requires re-run

      // request new data

      // on receive, call 'redraw'

    // else

      // redraw

      // save if requested
  }

  // clears changes and hides the hides the form
  function discard_changes() {
  
  }

  // redraws the report
  function redraw() {
    
    var tbl = $j("<table>");
    
    // header row
    var trow = $j("<tr>");
    $j(report.data.headers.col).each(function(idx, ch) {
      $j("<th>").addClass("col").text(ch).appendTo(trow);
    });
    
    tbl.append(trow);
    
    $j('#report_body').append(tbl);


    // update the title
  }
  
  // updates the title and subtitle of the report
  function set_title() {
    
    
  }

  // sends the report parameters to the server
  // along with an indication if the report should be run and/or if it should be saved 
  // if re-run is requested, report is redrawn on request completion
  // if request results in error, it is displayed and report is not redrawn
  function send() {
  
  }
}(report = {}));

// on page load
$j(document).ready(report.init);