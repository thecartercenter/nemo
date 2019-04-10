import React from 'react';
import PropTypes from 'prop-types';
import { observer, inject, Provider } from 'mobx-react';

import { createConditionSetStore } from './ConditionSetModel/utils';
import ConditionSetFormField from './ConditionSetFormField';

@inject('conditionSetStore')
@observer
class DisplayLogicFormFieldRoot extends React.Component {
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
    this.state = { refableQings, id, type, displayIf };

    // Directly assign initial values to the store.
    Object.assign(conditionSetStore, {
      formId,
      namePrefix: `${type}[display_conditions_attributes]`,
      conditions: displayConditions,
      conditionableId: id,
      conditionableType: 'FormItem',
      refableQings,
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
    const { type } = this.state;
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
    const { refableQings: rawRefableQings, id, type, displayIf } = this.state;
    // Display logic conditions can't reference self, as that doesn't make sense.
    const refableQings = rawRefableQings.filter((qing) => qing.id !== id);

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

const DisplayLogicFormField = (props) => (
  <Provider conditionSetStore={createConditionSetStore('displayLogic')}>
    <DisplayLogicFormFieldRoot {...props} />
  </Provider>
);

export default DisplayLogicFormField;
