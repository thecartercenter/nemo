import React from 'react';
import PropTypes from 'prop-types';

import ConstraintSetFormField from './ConstraintSetFormField/component';

class ConstraintsFormField extends React.Component {
  static propTypes = {
    type: PropTypes.string.isRequired,
    constraints: PropTypes.arrayOf(PropTypes.object).isRequired,
  };

  constructor(props) {
    super(props);
    const { constraints } = this.props;
    const constrain = constraints.length === 0 ? 'dont_constrain' : 'constrain';
    this.state = { constrain };
  }

  constrainOptionChanged = (event) => {
    this.setState({ constrain: event.target.value });
  }

  constrainOptionTags = () => {
    const constrainOptions = ['dont_constrain', 'constrain'];
    return constrainOptions.map((option) => (
      <option
        key={option}
        value={option}
      >
        {I18n.t(`form_item.constrain_options.${option}`)}
      </option>
    ));
  }

  render() {
    const { type } = this.props;
    const { constrain } = this.state;
    const selectProps = {
      className: 'form-control constrain-or-not',
      value: constrain,
      onChange: this.constrainOptionChanged,
      name: `${type}[constraints]`,
      id: `${type}_constraints`,
    };

    return (
      <div className="constraints-container">
        <select {...selectProps}>
          {this.constrainOptionTags()}
        </select>
        <ConstraintSetFormField
          hide={constrain === 'dont_constrain'}
          {...this.props}
        />
      </div>
    );
  }
}

export default ConstraintsFormField;
