const AJAX_RELOAD_INTERVAL = 30; // seconds
const PAGE_RELOAD_INTERVAL = 30; // minutes

ELMO.Views.DashboardView = class DashboardView extends ELMO.Views.ApplicationView {
  get el() { return 'body.dashboard'; }

  get events() {
    return {
      'click a.full-screen': 'handleFullScreen',
      'click a.toggle-map': 'handleExpandMap',
    };
  }

  initialize(params) {
    const self = this;
    this.params = params;

    // Setup ajax reload timer and test link.
    this.reload_timer = setTimeout(() => { self.reloadAjax(); }, AJAX_RELOAD_INTERVAL * 1000);
    $('a.reload-ajax').on('click', () => { self.reloadAjax(); });

    // Setup long-running page reload timer, unless it already exists.
    // This timer ensures that we don't have memory issues due to a long running page.
    if (!ELMO.app.dashboard_reload_timer) {
      ELMO.app.dashboard_reload_timer = setTimeout(() => { self.reloadPage(); }, PAGE_RELOAD_INTERVAL * 60000);
      $('a.reload-page').on('click', () => { self.reloadPage(); });
    }
    // save mission_id as map serialization key
    this.params.map.serialization_key = this.params.mission_id;

    // create classes for screen components
    this.list_view = new ELMO.Views.DashboardResponseList();
    this.map_view = new ELMO.Views.DashboardMapView(this.params.map);
    this.dashboard_report = new ELMO.Views.DashboardReportView();
  }

  handleFullScreen(e) {
    e.preventDefault();
    this.setFullScreen('toggle');
  }

  handleExpandMap(e) {
    e.preventDefault();
    this.setExpandedMap('toggle');
  }

  // Reloads the page via AJAX, passing the current report id
  reloadAjax() {
    this.dashboard_report.toggleLoader(true);

    // We only set the 'auto' parameter on this request if NOT in full screen mode.
    // The auto param prevents the AJAX request from resetting the auto-logout timer.
    // The dashboard in full screen mode is meant to be a long-running page so doesn't make
    // sense to let the session expire.
    const auto = this.viewSetting('full-screen') ? undefined : 1;

    const self = this;
    $.ajax({
      url: ELMO.app.url_builder.build('/'),
      method: 'GET',
      data: {
        latest_response_id: this.list_view.latestResponseId(),
        auto,
      },
      success(data) {
        $('.recent-responses').html(data.recent_responses);
        $('.stats').html(data.stats);
        $('.report').html(data.report);
        self.dashboard_report.toggleLoader(false);
        self.map_view.update_map(data.response_locations);
        self.reload_timer = setTimeout(() => { self.reloadAjax(); }, AJAX_RELOAD_INTERVAL * 1000);
      },
      error() {
        if (ELMO.unloading) return;
        $('#content').html(I18n.t('layout.server_contact_error'));
      },
    });
  }

  // Reloads the page via full refresh to avoid memory issues.
  reloadPage() {
    this.dashboard_report.showLoader();
    const nonce = Math.floor(Math.random() * 1000000 + 1);
    window.location.href = `${ELMO.app.url_builder.build('')}?r=${nonce}`;
  }

  // Enables/disables full screen mode. Uses stored setting if no param given.
  // Toggles setting if 'toggle' given.
  setFullScreen(value) {
    const full = this.viewSetting('full-screen', value);

    if (full) {
      $('#footer').hide();
      $('#main-nav').hide();
      $('#userinfo').hide();
      $('#logo img').css('height', '30px');
      $('a.full-screen i').removeClass('fa-expand').addClass('fa-compress');

    // No need to unset things if toggle not given since it's only called that way on page load
    // and the default is to hide.
    } else if (value === 'toggle') {
      $('#footer').show();
      $('#main-nav').show();
      $('#userinfo').show();
      $('#logo img').css('height', '54px'); // initial does weird stuff on first load with oversized logo
      $('a.full-screen i').removeClass('fa-compress').addClass('fa-expand');
    }

    // Set link text
    $('a.full-screen span').text(I18n.t(`dashboard.${full ? 'exit' : 'enter'}_full_screen`));
  }

  // Enables/disables expanded map. Uses stored setting if no param given.
  // Toggles setting if 'toggle' given.
  // Always enables full screen if expanding map.
  // When collapsing map, disables full screen if it wasn't on when map was expanded.
  setExpandedMap(value) {
    const expand = this.viewSetting('expanded-map', value);

    if (expand) {
      const wasFull = this.viewSetting('full-screen');
      this.viewSetting('screen-full-before-map-expand', wasFull);
      this.setFullScreen(true);

      $('#content').addClass('expanded-map');

    // No need to unset things if toggle not given since it's only called that way on page load
    // and the default is to hide.
    } else if (value === 'toggle') {
      const wasFull = this.viewSetting('screen-full-before-map-expand');
      if (!wasFull) this.setFullScreen(false);

      $('#content').removeClass('expanded-map');
    }
  }

  viewSetting(settingName, value) {
    let bool = JSON.parse(localStorage.getItem(settingName));

    // Return unchanged if no value given.
    if (typeof value === 'undefined') return bool;

    // Toggle if requested.
    else if (value === 'toggle') bool = !bool;

    // Else set directly.
    else bool = value;

    localStorage.setItem(settingName, bool);
    return bool;
  }
};
