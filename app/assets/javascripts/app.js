// ELMO.App
//
// handles general client side stuff that appears in the template (e.g. language chooser form)
(function (ns, klass) {
  const ALERT_CLASSES = {
    notice: 'alert-info',
    success: 'alert-success',
    error: 'alert-danger',
    alert: 'alert-warning',
  };

  // constructor
  ns.App = klass = function (params) {
    const self = this;
    self.params = params;

    // setup I18n module
    I18n.locale = self.params.locale;
    I18n.defaultLocale = self.params.default_locale;
    I18n.fallbacks = true;

    // Setup the UrlBuilder instance for all to use.
    self.url_builder = new ELMO.UrlBuilder({ locale: self.params.locale, mode: self.params.mode, mission_name: self.params.mission_name });

    // setup the language change form and link
    $('a#locale_form_link').on('click', function () { $('#locale_form').css('display', 'inline-block'); $(this).hide(); return false; });
    $('#locale_form select').on('change', function () { self.change_locale($(this).val()); return false; });

    // setup submit response dropdown in nav bar
    $('a.dropdown-toggle').on('click', function () { self.show_hide_submit_menu($(this)); return false; });

    // set session countdown
    self.reset_session_countdown();

    // listen for any ajax calls so we can update the session countdown
    // but don't update the countdown if the auto param is set, because those don't count
    $(document).bind('ajaxComplete', (event, xhr, ajaxopts) => {
      if (!ajaxopts.url.match(/\bauto=1\b/)) self.reset_session_countdown();
    });

    // Signal when the user is navigating to a different page, because that
    // causes XHR requests to fail in some browsers, and we can ignore those failures.
    $(window).on('beforeunload', () => {
      ELMO.unloading = true;
    });

    // prevent double submission of any forms on the page
    $('form').preventDoubleSubmission();

    self.set_alert_timeout();
  };

  // sets a countdown to session timeout
  klass.prototype.reset_session_countdown = function () {
    const self = this;
    if (self.params.logged_in) {
      // clear the old one
      if (self.session_countdown) clearTimeout(self.session_countdown);

      // set the new one (subtract 5s to account for transit times)
      self.session_countdown = setTimeout(() => { self.redirect_to_login(); }, self.params.session_timeout * 1000 - 5000);
    }
  };

  // redirects the user to the login page
  klass.prototype.redirect_to_login = function () {
    const self = this;
    window.location.href = self.params.login_path;
  };

  // changes the current locale by rewriting the url to use the new locale
  klass.prototype.change_locale = function (new_locale) {
    const self = this;
    // build a new url and go there
    window.location.href = ELMO.app.url_builder.build(window.location.pathname + window.location.search, { locale: new_locale });
  };

  // sets the title in h1.title and <title>
  klass.prototype.set_title = function (title) {
    const self = this;
    $('title').text(`${self.params.site_name}: ${title}`);
    $('h1.title').text(title);
  };

  // shows the dropdown menu that extends from the 'submit' link in the navbar
  klass.prototype.show_hide_submit_menu = function (link) {
    const self = this;

    // only load if haven't loaded before
    if (!link.next('ul').data('loaded')) {
      link.next('ul').data('loaded', true);

      // if hidden, show drop down
      if (link.next('ul').is(':hidden')) link.dropdown('toggle');

      // show loading ind
      link.next('ul').find('div.inline-load-ind img').show();

      link.next('ul').load(`${self.url_builder.build('forms')}?dropdown=1`, () => {
        // hide loading ind
        link.next('ul').find('div.inline-load-ind img').hide();
      });
    }
  };

  // Shows alert at top of page
  // params.type - success, error, notice, alert
  // params.tag - a dashified tag (e.g. option-sets) identifying the creator of the alert, to be used later when clearing
  // params.msg - the message
  klass.prototype.show_alert = function (params) {
    const self = this;
    $('<div>')
      .addClass('alert')
      .addClass(self.alert_type_class(params.type))
      .addClass(self.alert_tag_class(params.tag))
      .html(`<strong>${I18n.t(`common.${params.type}.one`)}:</strong> ${params.msg}`)
      .prependTo($('#content'));
    self.set_alert_timeout();
  };

  // removes all alerts
  klass.prototype.clear_alerts = function (params) {
    const self = this;
    params = params || {};
    // remove all alerts with given tag, or all alerts if no tag given
    $(`.${params.tag ? self.alert_tag_class(params.tag) : 'alert'}`).remove();
  };

  // gets css for alerts with given type
  klass.prototype.alert_type_class = function (type) {
    const self = this;
    return ALERT_CLASSES[type];
  };

  // gets css class for alerts with a given tag
  klass.prototype.alert_tag_class = function (tag) {
    const self = this;
    return tag ? `alert-for-${tag}` : '';
  };

  // hides any success alerts after a delay
  klass.prototype.set_alert_timeout = function () {
    const self = this;
    window.setTimeout(() => { $('.alert-success').slideUp(); return false; }, 4000);
  };

  // Shows/hides loading indicator.
  klass.prototype.loading = function (yn) {
    $('#glb-load-ind')[yn ? 'show' : 'hide']();
  };
}(ELMO));
