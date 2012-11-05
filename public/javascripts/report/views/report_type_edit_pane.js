// ELMO.Report.ReportTypeEditPane < ELMO.Report.EditPane
(function(ns, klass) {
  
  // constructor
  ns.ReportTypeEditPane = klass = function() {
    this.build()
  }

  // inherit from EditPane
  klass.prototype = new ns.EditPane();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.EditPane.prototype;
  
  klass.prototype.title = "Report Type";

  // builds controls
  klass.prototype.build = function() {
    var _this = this;
    
    // call super first
    this.parent.build.call(this);
    
    this.cont.append($("<div>").addClass("tip").text("What type of report would you like?"));
    
    this.type_chooser = new ELMO.Control.RadioGroup({
      name: "report_type",
      values: $(klass.TYPES).collect(function(){ return this.name }),
      labels_html: $(klass.TYPES).collect(function(){ return _this.build_label(this) }),
      field_before_label: true
    })
    this.type_chooser.append_all_to(this.cont);
  }
  
  // build html for a label
  klass.prototype.build_label = function(type) {
    var title = $("<h3>").text(type.title);
    var ex_lbl = $("<div>").addClass("ex_lbl").text("Examples:");
    var examples = $("<ul>");
    $.each(type.examples, function(i, ex) { examples.append($("<li>").text(ex)); })
    return title.after(ex_lbl).after(examples);
  }
  
  klass.prototype.update = function(report) {
    this.report = report;
    this.type_chooser.update(this.report.attribs.type);
  }

  // extracts data from the view into the model
  klass.prototype.extract = function() {
    this.report.attribs.type = this.type_chooser.get();
  }
  
  klass.TYPES = [{
    name: "Report::QuestionAnswerTallyReport",
    title: "Tally or percentage of answers per question",
    examples: [
      "Percentages of Yes, No, ... for all Yes-No questions",
      "Tally of zero and non-zero answers for questions about observers"
    ]
  }]           
  
  klass.prototype.fields_for_validation_errors = function() {
    return ["type"];
  }

}(ELMO.Report));