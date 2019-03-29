import React from 'react';

import ConditionSetFormField from './ConditionSetFormField';

class DisplayLogicFormField extends React.Component {
  constructor(props) {
    super(props);
    // TODO: Explicitly pick props to use.
    this.state = props;
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
      <div>
        <select {...displayIfProps}>
          {this.displayIfOptionTags()}
        </select>
        <ConditionSetFormField {...conditionSetProps} />
      </div>
    );
  }
}

export default DisplayLogicFormField;
