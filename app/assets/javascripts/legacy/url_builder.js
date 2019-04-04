// ELMO.UrlBuilder
(function (ns, klass) {
  // constructor
  ns.UrlBuilder = klass = function (params) {
    this.locale = params.locale;
    this.mode = params.mode;
    this.mission_name = params.mission_name;
  };

  klass.prototype.build = function () {
    // we need some funky magic to turn the arguments object into an array
    let args = Array.prototype.slice.call(arguments, 0);
    let options = {};

    // if the last arg is an options hash, extract it
    if (typeof (args[args.length - 1]) === 'object') {
      options = args[args.length - 1];
      args = args.slice(0, args.length - 1);
    }

    // default to the current locale and mission name
    options.locale = options.locale || this.locale;
    options.mode = options.mode || this.mode;
    options.mission_name = options.mission_name || this.mission_name;

    suffix = this.strip_scope(args.join('/'));

    let result;
    switch (options.mode) {
      case 'basic':
        result = `/${options.locale}/${suffix}`;
        break;
      case 'mission':
        result = `/${options.locale}/m/${options.mission_name}/${suffix}`;
        break;
      case 'admin':
        result = `/${options.locale}/admin/${suffix}`;
        break;
      default:
        throw 'invalid mode';
    }

    // return, fixing any double or trailing slashes
    return result.replace(/[\/]{2,}/g, '/').replace(/\/$/, '');
  };

  // Strips the locale and mission_name from the given path.
  klass.prototype.strip_scope = function (path) {
    let mode_mission;
    if (this.mode == 'mission') mode_mission = `m/${this.mission_name}`;
    else if (this.mode == 'admin') mode_mission = 'admin';
    else mode_mission = '';

    // replace the "/en/", "/en/m/mission", "/en/m/mission/", "/en", and "/" variants with "/"
    if (path == '' || path.match(new RegExp(`^\/([a-z]{2}(\/${mode_mission})?(\/)?)?$`))) return '/';
    // else fix the "/en/foo" or "/en/m/mission/foo" variants
    return path.replace(new RegExp(`^\/[a-z]{2}(\/${mode_mission})?\/(.+)`), (m, $1, $2) => { return `/${$2}`; });
  };
}(ELMO));
