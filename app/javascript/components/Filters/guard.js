import React from 'react';

import ErrorBoundary from '../ErrorBoundary/component';
import Injector from './injector';

/**
 * Top-level error boundary so no errors can leak out from this root component.
 *
 * Intended to be generic so it can be used anywhere we have a root
 * React component that gets rendered by Rails.
 */
function Guard(props) {
  return (
    <ErrorBoundary>
      <Injector {...props} />
    </ErrorBoundary>
  );
}

export default Guard;
