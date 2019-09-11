import React from 'react';
import Modal from 'react-bootstrap/Modal';
import Button from 'react-bootstrap/Button';
import PropTypes from 'prop-types';
import { inject, observer } from 'mobx-react';

@inject('conditionSetStore')
@observer
class RejectionModal extends React.Component {
  static propTypes = {
    title: PropTypes.string,
    show: PropTypes.bool,
    handleClose: PropTypes.func,
    namePrefix: PropTypes.string,
    rejectionMsgTranslations: PropTypes.object,
  };

  static defaultProps = {
    show: false,
  };

  constructor(props) {
    super(props);
    this.state = props.rejectionMsgTranslations;
  }

  render() {
    const { show, title, handleClose, namePrefix } = this.props;
    const rejectionMsgs = this.state;
    const inputs = ELMO.app.params.preferred_locales.map((locale) => (
      <input type="hidden" key={locale} name={`${namePrefix}[rejection_msg_translations][${locale}]`} value={rejectionMsgs[locale]} onChange={(e) => this.setState({ [locale]: e.target.value })} />
    ));

    const fields = ELMO.app.params.preferred_locales.map((locale) => (
      <div className="form-field" key={locale}>
        <label className="main" htmlFor={`${namePrefix}[rejection_msg_translations][${locale}]`}>{I18n.t('locale_name', { locale })}</label>
        <div className="control">
          <div className="widget">
            <input
              className="form-control"
              id={`${namePrefix}[rejection_msg_translations][${locale}]`}
              type="text"
              value={rejectionMsgs[locale]}
              onChange={(e) => this.setState({ [locale]: e.target.value })}
            />
          </div>
        </div>
      </div>
    ));
    return (
      <>
        {/* These hidden inputs are placed here outside the modal because the modal gets moved/inserted
          at the bottom of the `<body>` tag outside the form element. If we don't have the hidden inputs,
          the data isnt included in the submission. */}
        {inputs}
        <Modal show={show} onHide={handleClose}>
          <Modal.Header closeButton>
            <Modal.Title>{title}</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <div className="elmo-form">
              { fields }
            </div>
          </Modal.Body>
          <Modal.Footer>
            <Button variant="secondary" onClick={handleClose}>Close</Button>
            <Button variant="primary" onClick={handleClose}>Save</Button>
          </Modal.Footer>
        </Modal>
      </>
    );
  }
}

export default RejectionModal;
