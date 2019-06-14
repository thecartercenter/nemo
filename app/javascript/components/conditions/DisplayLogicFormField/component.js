import React from 'react';
import PropTypes from 'prop-types';
import { observer, inject } from 'mobx-react';

import ConditionSetFormField from '../ConditionSetFormField/component';

@inject('conditionSetStore')
@observer
class DisplayLogicFormField extends React.Component {
  static propTypes = {
    conditionSetStore: PropTypes.object.isRequired,

    // TODO: Describe these prop types.
    /* eslint-disable react/forbid-prop-types */
    refableQings: PropTypes.any,
    id: PropTypes.any,
    type: PropTypes.any,
    displayIf: PropTypes.any,
    displayConditions: PropTypes.any,
    formId: PropTypes.any,
    /* eslint-enable */
  };

  constructor(props) {
    super(props);
    const { conditionSetStore, refableQings, id, type, displayIf, displayConditions, formId } = this.props;
    this.state = { displayIf };

    conditionSetStore.initialize({
      formId,
      namePrefix: `${type}[display_conditions_attributes]`,
      conditions: displayConditions,
      conditionableId: id,
      conditionableType: 'FormItem',
      // Display logic conditions can't reference self, as that doesn't make sense.
      refableQings: refableQings.filter((qing) => qing.id !== id),
      hide: displayIf === 'always',
    });
  }

  displayIfChanged = (event) => {
    const { conditionSetStore } = this.props;
    const displayIf = event.target.value;
    this.setState({ displayIf });
    conditionSetStore.hide = displayIf === 'always';
  }

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
  }

  render() {
    const { refableQings, type } = this.props;
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
        <ConditionSetFormField />
      </div>
    );
  }
}

export default DisplayLogicFormField;
