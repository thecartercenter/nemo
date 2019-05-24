import React, { Component } from 'react';
import PropTypes from 'prop-types';

class ErrorBoundary extends Component {
  static propTypes = {
    message: PropTypes.string,
    children: PropTypes.node.isRequired,
  };

  static defaultProps = {
    message: I18n.t('common.jsError'),
  };

  state = {
    hasError: false,
  };

  componentDidCatch(error, info) {
    if (process.env.NODE_ENV !== 'test') {
      console.error('[Boundary error]', error);
      console.error('[Boundary info]', info);
    }

    this.setState({ hasError: true });
  }

  render = () => {
    const { hasError } = this.state;
    const { message, children } = this.props;

    if (!hasError) return children;

    return (
      <div className="alert alert-danger" role="alert">
        {message}
      </div>
    );
  };
}

export default ErrorBoundary;
