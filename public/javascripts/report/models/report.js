// ELMO.Report.Report
(function(ns, klass) {
  
  // constructor
  ns.Report = klass = function(attribs, menus) {
    this.attribs = attribs;
    this.menus = menus;
  }
  
  // called when data first received
  klass.prototype.prepare = function() {
    this.extract_form_ids_from_filter_str();
  }
  
  klass.prototype.clone = function() {
    var new_attribs = $.extend(true, {}, this.attribs);
    return new klass(new_attribs, this.menus);
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
    
    if (this.attribs.type != "Report::QuestionAnswerTallyReport") return;
    
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
  
  // returns a filter string fragment for the selected form ids
  klass.prototype.form_filter_str = function() {
    if (this.attribs.form_ids == "ALL")
      return null;
    else
      return "form:\"" + this.menus.form.get_names(this.attribs.form_ids).join("\",\"") + "\"";
  }
  
  klass.prototype.extract_form_ids_from_filter_str = function() {
    var m;
    if (m = this.attribs.filter_str.match(/^\(form:(.*)\)( and \((.+)\))?/)) {
      this.attribs.filter_str = m[3] || "";
      
      // split name str and strip quotes
      var names = m[1].split(",");
      $(names).each(function(i){ names[i] = names[i].substring(1, names[i].length - 1); });
      
      // get ids from form menu
      this.attribs.form_ids = this.menus.form.get_ids_from_names(names);
    } else {
      this.attribs.form_ids = "ALL";
    }
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
    if (this.attribs.type == "Report::QuestionAnswerTallyReport") {
      to_serialize.calculations_attributes = [];
      for (var i = 0; i < this.attribs.calculations.length; i++) {
        var calc = {};
        calc.question1_id = this.attribs.calculations[i].question1_id;
        if (this.attribs.calculations[i].type) calc.type = this.attribs.calculations[i].type;
        if (this.attribs.calculations[i].id) calc.id = this.attribs.calculations[i].id;
        if (this.attribs.calculations[i]._destroy) calc._destroy = this.attribs.calculations[i]._destroy;
        to_serialize.calculations_attributes.push(calc);
      }
    } else {
      to_serialize.calculations_attributes = this.attribs.calculations_attributes;

      // fix ranks
      if (this.attribs.calculations_attributes)
        for (var i = 0; i < this.attribs.calculations_attributes.length; i++)
          if (this.attribs.calculations_attributes[i].type)
            this.attribs.calculations_attributes[i].rank = i + 1;
    }
    
    // filter params
    to_serialize.filter_attributes = {}
    to_serialize.filter_attributes.class_name = "Response"

    // include the form id spec in the filter string
    var filter_clauses = []
    var form_str = this.form_filter_str();
    if (form_str) filter_clauses.push("(" + form_str + ")");
    if (this.attribs.filter_str.length > 0) filter_clauses.push("(" + this.attribs.filter_str + ")");
    
    to_serialize.filter_attributes.str = filter_clauses.join(" and ")
    
    return to_serialize;
  }
  
  klass.prototype.calculation_by_rank = function(rank) {
    if (!this.attribs.calculations)
      return null;
      
    for (var i = 0; i < this.attribs.calculations.length; i++)
      if (this.attribs.calculations[i].rank == rank)
        return this.attribs.calculations[i];
    return null;
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
    if (this.attribs.type == "Report::QuestionAnswerTallyReport" && this.calculation_count() == 0 && this.attribs.option_set_id == null)
      this.errors.add("questions", "You must choose at least one question or one option set.");
    return this.errors.empty();
  }
  
}(ELMO.Report));