import React from 'react';
import PropTypes from 'prop-types';
import { observer, inject, Provider } from 'mobx-react';

import { createQuestionFilterStore } from './search/utils';
import ConditionSetFormField from './ConditionSetFormField';

@inject('questionStore')
@observer
class DisplayLogicFormFieldRoot extends React.Component {
  static propTypes = {
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
    const { refableQings, id, type, displayIf, displayConditions, formId } = this.props;
    this.state = { refableQings, id, type, displayIf, displayConditions, formId };
  }

  displayIfChanged = (event) => {
    this.setState({ displayIf: event.target.value });
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
    const { refableQings: rawRefableQings, id, type, displayIf, displayConditions, formId } = this.state;
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
    const conditionSetProps = {
      conditions: displayConditions,
      conditionableId: id,
      conditionableType: 'FormItem',
      refableQings,
      formId,
      hide: displayIf === 'always',
      namePrefix: `${type}[display_conditions_attributes]`,
    };

    return (
      <div className="display-logic-container">
        <select {...displayIfProps}>
          {this.displayIfOptionTags()}
        </select>
        <ConditionSetFormField {...conditionSetProps} />
      </div>
    );
  }
}

const DisplayLogicFormField = (props) => (
  <Provider questionStore={createQuestionFilterStore('displayLogic')}>
    <DisplayLogicFormFieldRoot {...props} />
  </Provider>
);

export default DisplayLogicFormField;
