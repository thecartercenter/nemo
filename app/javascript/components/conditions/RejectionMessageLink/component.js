import React from 'react';
import PropTypes from 'prop-types';
import { inject, observer } from 'mobx-react';

@inject('conditionSetStore')
@observer
class RejectionMessageLink extends React.Component {
  static propTypes = {
    conditionSetStore: PropTypes.object,
  };

  handleOnClick = () => {
    const { conditionSetStore: { setCustomMessage } } = this.props;
    setCustomMessage();
  }

  render() {
    const { conditionSetStore: { customRejectionMessage } } = this.props;
    /* Update to use translations table. */
    const messageId = customRejectionMessage !== null ? 'form_item.rejection_message.edit' : 'form_item.rejection_message.add';
    return (
      <React.Fragment>
        {/* eslint-disable-next-line */}
        <a onClick={this.handleOnClick} tabIndex="0">
          <i className="fa fa-pencil edit-rejection-message" />
          {' '}
          { I18n.t(messageId) }
        </a>
        {/* eslint-enable */}
      </React.Fragment>
    );
  }
}

export default RejectionMessageLink;
