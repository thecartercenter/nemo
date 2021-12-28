import React from 'react';
import PropTypes from 'prop-types';
import { observer, inject } from 'mobx-react';

import ConditionSetFormField from '../ConditionSetFormField/component';
import AddConditionLink from '../AddConditionLink/component';

@inject('conditionSetStore')
@observer
class DisplayLogicFormField extends React.Component {
  static propTypes = {
    conditionSetStore: PropTypes.object.isRequired,
    type: PropTypes.string,
    displayIf: PropTypes.string,
  };

  constructor(props) {
    super(props);
    const { displayIf } = this.props;
    this.state = { displayIf };
  }

  displayIfChanged = (event) => {
    const { conditionSetStore } = this.props;
    const displayIf = event.target.value;
    this.setState({ displayIf });
    conditionSetStore.hide = displayIf === 'always';
  };

  displayIfOptionTags = () => {
    const { type } = this.props;
    const displayIfOptions = ['always', 'all_met', 'any_met'];
    return displayIfOptions.map((option) => (
      <option
        key={option}
        value={option}
      >
        {I18n.t(`form_item.display_if_options.${type}.${option}`)}
      </option>
    ));
  };

  render() {
    const { conditionSetStore, type } = this.props;
    const { refableQings } = conditionSetStore;
    const { displayIf } = this.state;

    if (refableQings.length === 0) {
      return (
        <div>
          {I18n.t('condition.no_refable_qings')}
        </div>
      );
    }
    const displayIfProps = {
      className: 'form-control',
      name: `${type}[display_if]`,
      id: `${type}_display_logic`,
      value: displayIf,
      onChange: this.displayIfChanged,
    };

    return (
      <div className="display-logic-container">
        <select {...displayIfProps}>
          {this.displayIfOptionTags()}
        </select>
        <div
          className="rule-set"
          style={{ display: displayIf === 'always' ? 'none' : '' }}
        >
          <ConditionSetFormField />
          {displayIf !== 'always' && (
            <AddConditionLink />
          )}
        </div>
      </div>
    );
  }
}

export default DisplayLogicFormField;
