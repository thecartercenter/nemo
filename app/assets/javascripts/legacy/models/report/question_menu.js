// ELMO.Report.QuestionMenu < ELMO.Report.ObjectMenu
(function (ns, klass) {
  // constructor
  klass = ns.QuestionMenu = function (questions) {
    this.objs = questions;
    this.cache = {};
  };

  // inherit
  klass.prototype = new ns.ObjectMenu();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.ObjectMenu.prototype;


  // filter questions by calc_type, form_ids, question_types, and geographic
  klass.prototype.filter = function (options) {
    const o = [];

    // default to identity calculation
    if (!options.calc_type) options.calc_type = 'identity';

    // default to no form ids
    if (!options.form_ids || options.form_ids == 'ALL') options.form_ids = [];

    // Sort the form_id array to increase likelihood of cache hits.
    options.form_ids = options.form_ids.sort();

    // sort the question types also
    if (options.question_types) options.question_types = options.question_types.sort();
    else options.question_types = [];

    // build cache key
    let cache_key = `${options.calc_type}|${options.form_ids.join(',')}|${options.question_types.join(',')}`;
    if (options.geographic !== undefined) cache_key += `|${options.geographic ? 'geo' : 'nogeo'}`;

    // try the cache
    if (this.cache[cache_key]) return this.cache[cache_key];

    for (let i = 0; i < this.objs.length; i++) {
      const type = this.objs[i].qtype_name;
      // ZeroNonzeroCalculations must have integer or decimal questions
      if (options.calc_type == 'zero_nonzero' && !(type == 'integer' || type == 'decimal')) continue;

      // IdentityCalculation can have any type given in question_types
      if (options.calc_type == 'identity' && options.question_types.length > 0 && options.question_types.indexOf(this.objs[i].qtype_name) == -1) continue;

      // question must appear on one of the given forms
      if (options.form_ids.length > 0 && Sassafras.Utils.intersect(this.objs[i].form_ids, options.form_ids).length == 0) continue;

      // respect the geographic option
      if (options.geographic !== undefined && this.objs[i]['geographic?'] !== options.geographic) continue;

      // if we get this far, we can push
      o.push(this.objs[i]);
    }

    // save the matching questions for the given options to the cache as this method is likely to be called in bursts
    this.cache[cache_key] = o;

    return o;
  };
}(ELMO.Report));
