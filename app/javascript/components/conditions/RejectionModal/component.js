import React from 'react';
import Modal from 'react-bootstrap/Modal';
import Button from 'react-bootstrap/Button';
import PropTypes from 'prop-types';
import { inject, observer } from 'mobx-react';

@inject('conditionSetStore')
@observer
class RejectionModal extends React.Component {
  static propTypes = {
    conditionSetStore: PropTypes.object,
    title: PropTypes.string,
    show: PropTypes.bool,
    handleClose: PropTypes.func,
  };

  static defaultProps = {
    title: 'Add Rejection Message',
    show: false,
  };

  handleChange = (e) => {
    const { conditionSetStore: { setRejectionMessage } } = this.props;
    setRejectionMessage(e.target.value);
  }

  render() {
    const { show, title, handleClose, conditionSetStore: { rejectionMsgTranslations } } = this.props;
    return (
      <Modal show={show} onHide={handleClose}>
        <Modal.Header closeButton>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <div className="elmo-form">
            <div className="form-field">
              <label className="main" htmlFor="rejection-message">Message:</label>
              <div className="control">
                <div className="widget">
                  <input id="rejection-message" className="form-control" type="text" value={rejectionMsgTranslations.en} onChange={this.handleChange} />
                </div>
              </div>
            </div>
          </div>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={handleClose}>Close</Button>
          <Button variant="primary" onClick={handleClose}>Save</Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

export default RejectionModal;
