import React from 'react';
import PropTypes from 'prop-types';
import { observer } from 'mobx-react';
import Form from 'react-bootstrap/Form';

import ConditionSetFormField from '../../../ConditionSetFormField/component';

@observer
class ConstraintFormField extends React.Component {
  static propTypes = {
    id: PropTypes.string,
    constraintId: PropTypes.string.isRequired,
    acceptIf: PropTypes.string.isRequired,
    hide: PropTypes.bool,
    namePrefix: PropTypes.string.isRequired,
    remove: PropTypes.bool,
  };

  static defaultProps = {
    remove: false,
    hide: false,
  };

  constructor(props) {
    super(props);

    const {
      remove,
      acceptIf,
    } = this.props;

    this.state = {
      remove,
      acceptIf,
    };
  }

  handleAcceptIfChange = (event) => {
    const acceptIf = event.target.value;
    this.setState({ acceptIf });
  }

  handleRemoveClick = () => {
    this.setState({ remove: true });
  }

  shouldDestroy = () => {
    const { hide } = this.props;
    const { remove } = this.state;
    return remove || hide;
  }

  render() {
    const { id, namePrefix, constraintId } = this.props;
    const { acceptIf } = this.state;

    return (
      <div
        className="constraint"
        style={{ display: this.shouldDestroy() ? 'none' : '' }}
      >
        <div className="constraint-main">
          <div className="constraint-attribs">
            <div className={`constraint-remove ${constraintId}`}>
              {/* TODO: Improve a11y. */}
              {/* eslint-disable-next-line */}
              <a onClick={this.handleRemoveClick}>
                <i className="fa fa-close" />
              </a>
            </div>
          </div>
          <ConditionSetFormField />
          <div key="accept-if">
            {['all_met', 'any_met'].map((key) => (
              <Form.Check
                inline
                checked={acceptIf === key}
                onChange={this.handleAcceptIfChange}
                label={I18n.t(`form_item.accept_if_options.${key}`)}
                type="radio"
                value={key}
                key={key}
              />
            ))}
          </div>
          <input
            type="hidden"
            name={`${namePrefix}[id]`}
            value={id || ''}
          />
          <input
            type="hidden"
            name={`${namePrefix}[_destroy]`}
            value={this.shouldDestroy() ? '1' : '0'}
          />
        </div>
      </div>
    );
  }
}

export default ConstraintFormField;
