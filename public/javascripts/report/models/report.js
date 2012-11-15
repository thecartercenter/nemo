// ELMO.Report.Report
(function(ns, klass) {
  
  // constructor
  ns.Report = klass = function(attribs) {
    this.attribs = attribs;
  }
  
  klass.prototype.clone = function() {
    var new_attribs = $.extend(true, {}, this.attribs);
    return new klass(new_attribs);
  }
  
  klass.prototype.has_run = function() {
    return !this.attribs.new_record;
  }
  
  // scans through all calculations and returns an array of question ids
  klass.prototype.get_calculation_question_ids = function() {
    var qids = [];
    if (this.attribs.calculations)
      for (var i = 0; i < this.attribs.calculations.length; i++)
        if (this.attribs.calculations[i].question1_id)
          qids.push(this.attribs.calculations[i].question1_id);
    return qids;
  }
  
  klass.prototype.set_calculations_by_question_ids = function(qids) {
    var _this = this;
    
    // calculations to empty array if not exist
    this.attribs.calculations = this.attribs.calculations || [];
    
    // do a match thing: if found, leave; if not found, set _destroy; if new, create new with no id
    Sassafras.Utils.match_lists(
      {list: this.attribs.calculations, comparator: function(c){ return c.question1_id.toString() + ":" + c.type; }}, 
      {list: qids, comparator: function(id){ return id + ":" + _this.attribs.omnibus_calculation; }},
      function(current_calc, new_id) {
        // if new_id has no accompanying current_calc, create a new one
        if (current_calc == null)
          _this.attribs.calculations.push({question1_id: new_id, type: _this.attribs.omnibus_calculation});
      
        // if current_calc is not in the given qids, mark it for destruction
        if (new_id == null)
          current_calc._destroy = "true";
      }
    )
  }
  
  // counts non-destroyed calculations
  klass.prototype.calculation_count = function() {
    var count = 0;
    for (var i = 0; i < this.attribs.calculations.length; i++)
      if (!this.attribs.calculations[i]._destroy)
        count++;
    return count;
  }
  
  klass.prototype.aggregation = function() {
    return this.attribs.aggregation_name || "Tally";
  }
  
  klass.prototype.to_hash = function() {
    var to_serialize = {}
    // later should replace this with better serialization method?
    to_serialize.type = this.attribs.type;
    to_serialize.name = this.attribs.name;
    to_serialize.display_type = this.attribs.display_type;
    to_serialize.percent_type = this.attribs.percent_type;
    to_serialize.bar_style = this.attribs.bar_style;
    to_serialize.question_labels = this.attribs.question_labels;
    to_serialize.option_set_id = this.attribs.option_set_id == null ? "" : this.attribs.option_set_id;
    to_serialize.calculations_attributes = [];
    for (var i = 0; i < this.attribs.calculations.length; i++) {
      var calc = {};
      calc.question1_id = this.attribs.calculations[i].question1_id;
      if (this.attribs.calculations[i].type) calc.type = this.attribs.calculations[i].type;
      if (this.attribs.calculations[i].id) calc.id = this.attribs.calculations[i].id;
      if (this.attribs.calculations[i]._destroy) calc._destroy = this.attribs.calculations[i]._destroy;
      to_serialize.calculations_attributes.push(calc);
    }
    return to_serialize;
  }
  
  // checks that all attributes are valid. 
  // returns true if valid.
  // returns false if invalid and sets validation errors.
  klass.prototype.validate = function() {
    this.errors = new ns.Errors();

    // type
    if (!this.attribs.type)
      this.errors.add("type", "You must choose a report type.");

    // type
    if (!this.attribs.name.match(/\w+/))
      this.errors.add("name", "You must enter a report title.");

    // question/option_set
    if (this.calculation_count() == 0 && this.attribs.option_set_id == null)
      this.errors.add("questions", "You must choose at least one question or one option set.");
    return this.errors.empty();
  }
  
}(ELMO.Report));