import React, { Component } from 'react';
import PropTypes from 'prop-types';
import * as Sentry from '@sentry/react';

function ErrorFallback({ message }) {
  return (
    <div className="alert alert-danger" role="alert">
      {message}
    </div>
  );
}

ErrorFallback.propTypes = {
  message: PropTypes.string,
};

class ErrorBoundary extends Component {
  static propTypes = {
    message: PropTypes.string,
    children: PropTypes.node.isRequired,
  };

  static defaultProps = {
    message: I18n.t('common.jsError'),
  };

  render() {
    const { message, children } = this.props;

    return (
      <Sentry.ErrorBoundary fallback={<ErrorFallback message={message} />}>
        {children}
      </Sentry.ErrorBoundary>
    );
  }
}

export default ErrorBoundary;
