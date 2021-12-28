import React from 'react';
import PropTypes from 'prop-types';
import { inject, observer } from 'mobx-react';

import RejectionModal from './RejectionModal/component';

@inject('conditionSetStore')
@observer
class RejectionMessageLink extends React.Component {
  static propTypes = {
    rejectionMsgTranslations: PropTypes.object,
    namePrefix: PropTypes.string,
  };

  constructor(props) {
    super(props);

    this.state = {
      show: false,
    };
  }

  handleShow = () => this.setState({ show: true });

  handleClose = () => {
    this.setState({ show: false });
  };

  render() {
    const { show } = this.state;
    const { rejectionMsgTranslations, namePrefix } = this.props;
    const messageId = Object.values(rejectionMsgTranslations).length === 0
      ? 'form_item.rejection_message.add'
      : 'form_item.rejection_message.edit';
    return (
      <>
        {/* eslint-disable-next-line */}
        <a href="#" onClick={this.handleShow} tabIndex="0">
          <i className="fa fa-pencil edit-rejection-message" />
          {' '}
          { I18n.t(messageId) }
        </a>

        <RejectionModal
          show={show}
          title={I18n.t(messageId)}
          handleClose={this.handleClose}
          namePrefix={namePrefix}
          rejectionMsgTranslations={rejectionMsgTranslations}
        />
        {/* eslint-enable */}
      </>
    );
  }
}

export default RejectionMessageLink;
