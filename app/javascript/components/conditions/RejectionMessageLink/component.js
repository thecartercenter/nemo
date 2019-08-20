import React from 'react';
import PropTypes from 'prop-types';
import { inject, observer } from 'mobx-react';

import RejectionModal from '../RejectionModal/component';

@inject('conditionSetStore')
@observer
class RejectionMessageLink extends React.Component {
  static propTypes = {
    conditionSetStore: PropTypes.object,
    rejectionMsgTranslations: PropTypes.object,
  };

  constructor(props) {
    super(props);

    this.state = {
      show: false,
    };
  }

  handleShow = () => this.setState({ show: true })

  handleClose = () => {
    this.setState({ show: false });
  }

  render() {
    const { show } = this.state;
    const { conditionSetStore: { rejectionMsgTranslations } } = this.props;
    const messageId = rejectionMsgTranslations.en ? 'form_item.rejection_message.edit' : 'form_item.rejection_message.add';
    return (
      <React.Fragment>
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
        />
        {/* eslint-enable */}
      </React.Fragment>
    );
  }
}

export default RejectionMessageLink;
