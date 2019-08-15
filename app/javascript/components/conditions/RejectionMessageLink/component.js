import React from 'react';
import PropTypes from 'prop-types';
import { inject, observer } from 'mobx-react';

@inject()
@observer
class RejectionMessageLink extends React.Component {
  static propTypes = {
    hasCustomMessage: PropTypes.bool,
  };

  static defaultProps = {};

  handleOnClick = () => {}

  render() {
    const { hasCustomMessage } = this.props;
    /* Update to use translations table. */
    const message = hasCustomMessage ? 'Edit Rejection Message' : 'Add Rejection Message';
    return (
      <React.Fragment>
        {/* eslint-disable-next-line */}
        <a onClick={this.handleOnClick} tabIndex="0">
          <i className="fa fa-pencil edit-rejection-message" />
          {' '}
          { message }
        </a>
        {/* eslint-enable */}
      </React.Fragment>
    );
  }
}

export default RejectionMessageLink;
