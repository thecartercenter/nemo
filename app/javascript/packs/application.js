/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

import 'core-js/stable';
import 'regenerator-runtime/runtime';

import * as Sentry from '@sentry/react';
import { Integrations } from '@sentry/tracing';

const isOnline = !process.env.NEMO_OFFLINE_MODE || process.env.NEMO_OFFLINE_MODE === 'false';
if (isOnline && process.env.NODE_ENV !== 'test') {
  Sentry.init({
    dsn: process.env.NEMO_SENTRY_DSN,
    integrations: [new Integrations.BrowserTracing()],

    // Uncomment to enable Sentry performance monitoring (disabled in favor of Scout).
    // Percentage between 0.0 - 1.0.
    // tracesSampleRate: 1.0,
  });
}

// Support component names relative to this directory:
const componentRequireContext = require.context('components', true);
const ReactRailsUJS = require('react_ujs');

ReactRailsUJS.useContext(componentRequireContext);
