// ELMO.Views.Dashboard
//
// View model for the Dashboard
(function (ns, klass) {
  const AJAX_RELOAD_INTERVAL = 30; // seconds
  const PAGE_RELOAD_INTERVAL = 30; // minutes

  // constructor
  ns.Dashboard = klass = function (params) {
    const self = this;
    self.params = params;

    // hook up full screen link
    $('a.full-screen').on('click', (obj) => {
      self.set_full_screen('toggle');
      return false;
    });

    // hook up expand map link
    $('a.toggle-map').on('click', (obj) => {
      self.set_expanded_map('toggle');
      return false;
    });

    // Setup ajax reload timer and test link.
    self.reload_timer = setTimeout(() => { self.reload_ajax(); }, AJAX_RELOAD_INTERVAL * 1000);
    $('a.reload-ajax').on('click', () => { self.reload_ajax(); });

    // Setup long-running page reload timer, unless it already exists.
    // This timer ensures that we don't have memory issues due to a long running page.
    if (!ELMO.app.dashboard_reload_timer) {
      ELMO.app.dashboard_reload_timer = setTimeout(() => { self.reload_page(); }, PAGE_RELOAD_INTERVAL * 60000);
      $('a.reload-page').on('click', () => { self.reload_page(); });
    }
    // save mission_id as map serialization key
    self.params.map.serialization_key = self.params.mission_id;

    // create classes for screen components
    self.list_view = new ELMO.Views.DashboardResponseList();
    self.map_view = new ELMO.Views.DashboardMapView(self.params.map);
    self.dashboard_report = new ELMO.Views.DashboardReport();
  };

  // Reloads the page via AJAX, passing the current report id
  klass.prototype.reload_ajax = function (args) {
    const self = this;

    // We only set the 'auto' parameter on this request if NOT in full screen mode.
    // The auto param prevents the AJAX request from resetting the auto-logout timer.
    // The dashboard in full screen mode is meant to be a long-running page so doesn't make
    // sense to let the session expire.
    const auto = view_setting('full-screen') ? undefined : 1;

    $.ajax({
      url: ELMO.app.url_builder.build('/'),
      method: 'GET',
      data: {
        latest_response_id: self.list_view.latest_response_id(),
        auto,
      },
      success(data) {
        $('.recent-responses').replaceWith(data.recent_responses);
        $('.stats').replaceWith(data.stats);
        $('.report-output-and-modal').html(data.report);
        self.map_view.update_map(data.response_locations);

        self.reload_timer = setTimeout(() => { self.reload_ajax(); }, AJAX_RELOAD_INTERVAL * 1000);
      },
      error() {
        if (ELMO.unloading) return;
        $('#content').html(I18n.t('layout.server_contact_error'));
      },
    });
  };

  // Reloads the page via full refresh to avoid memory issues.
  klass.prototype.reload_page = function () {
    const nonce = Math.floor(Math.random() * 1000000 + 1);
    window.location.href = `${ELMO.app.url_builder.build('')}?r=${nonce}`;
  };

  // Enables/disables full screen mode. Uses stored setting if no param given.
  // Toggles setting if 'toggle' given.
  klass.prototype.set_full_screen = function (value) {
    const full = view_setting('full-screen', value);

    if (full) {
      $('#footer').hide();
      $('#main-nav').hide();
      $('#userinfo').hide();
      $('#logo img').css('height', '30px');
      $('a.full-screen i').removeClass('fa-expand').addClass('fa-compress');
    } else {
      $('#footer').show();
      $('#main-nav').show();
      $('#userinfo').show();
      $('#logo img').css('height', '54px'); // initial does weird stuff on first load with oversized logo
      $('a.full-screen i').removeClass('fa-compress').addClass('fa-expand');
    }

    // Set link text
    $('a.full-screen span').text(I18n.t(`dashboard.${full ? 'exit' : 'enter'}_full_screen`));
  };

  // Enables/disables expanded map. Uses stored setting if no param given.
  // Toggles setting if 'toggle' given.
  // Always enables full screen if expanding map.
  // When collapsing map, disables full screen if it wasn't on when map was expanded.
  klass.prototype.set_expanded_map = function (value) {
    const expand = view_setting('expanded-map', value);

    if (expand) {
      var was_full = view_setting('full-screen');
      view_setting('screen-full-before-map-expand', was_full);
      this.set_full_screen(true);

      $('#content').addClass('expanded-map');
    } else {
      var was_full = view_setting('screen-full-before-map-expand');
      if (!was_full) this.set_full_screen(false);

      $('#content').removeClass('expanded-map');
    }
  };

  function view_setting(setting_name, value) {
    // Fetch current.
    let bool = JSON.parse(localStorage.getItem(setting_name));

    // Return unchanged if no value given.
    if (typeof value === 'undefined') return bool;

    // Toggle if requested.
    else if (value == 'toggle') bool = !bool;

    // Else set directly.
    else bool = value;

    // Store for future recall.
    localStorage.setItem(setting_name, bool);

    return bool;
  }
}(ELMO.Views));
