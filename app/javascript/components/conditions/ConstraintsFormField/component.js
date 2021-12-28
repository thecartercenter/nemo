import React from 'react';
import PropTypes from 'prop-types';

import ConstraintFormField from './ConstraintFormField';

class ConstraintsFormField extends React.Component {
  static propTypes = {
    type: PropTypes.string.isRequired,
    constraints: PropTypes.arrayOf(PropTypes.object).isRequired,
    refableQings: PropTypes.arrayOf(PropTypes.object),
  };

  constructor(props) {
    super(props);
    const { constraints } = this.props;
    const constrain = constraints.length === 0 ? 'dont_constrain' : 'constrain';
    this.state = { constrain, constraints };
  }

  constrainOptionChanged = (event) => {
    const { constraints } = this.state;
    this.setState({ constrain: event.target.value });
    if (event.target.value === 'constrain' && constraints.length === 0) {
      this.handleAddClick();
    }
  };

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
  };

  handleAddClick = () => {
    this.setState(({ constraints }) => ({
      constraints: constraints.concat([{
        key: Math.round(Math.random() * 100000000),
        acceptIf: 'all_met',
        conditions: [],
      }]),
    }));
  };

  render() {
    const { type, refableQings } = this.props;
    const { constrain, constraints } = this.state;
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
        <div
          className="rule-set"
          style={{ display: constrain === 'dont_constrain' ? 'none' : '' }}
        >
          {constraints.map((constraint, index) => (
            <ConstraintFormField
              hide={constrain === 'dont_constrain'}
              key={constraint.key || constraint.id}
              constraintId={`constraint-${index + 1}`}
              namePrefix={`questioning[constraints_attributes][${index}]`}
              refableQings={refableQings}
              {...constraint}
            />
          ))}
          <div
            className="rule-add-link-wrapper"
          >
            {/* TODO: Improve a11y. */}
            {/* eslint-disable */}
            <a
              onClick={this.handleAddClick}
              tabIndex="0"
            >
            {/* eslint-enable */}
              <i className="fa fa-plus" />
              {' '}
              {I18n.t('form_item.add_rule')}
            </a>
          </div>
        </div>
      </div>
    );
  }
}

export default ConstraintsFormField;
