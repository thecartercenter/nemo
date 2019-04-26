import React from 'react';
import PropTypes from 'prop-types';

import SkipRuleSetFormField from './SkipRuleSetFormField';

class SkipLogicFormField extends React.Component {
  static propTypes = {
    type: PropTypes.string.isRequired,
    skipRules: PropTypes.arrayOf(PropTypes.object).isRequired,
  };

  constructor(props) {
    super(props);
    const { type, skipRules } = this.props;
    const skip = skipRules.length === 0 ? 'dont_skip' : 'skip';
    this.state = { type, skip };
  }

  skipOptionChanged = (event) => {
    this.setState({ skip: event.target.value });
  }

  skipOptionTags = () => {
    const skipOptions = ['dont_skip', 'skip'];
    return skipOptions.map((option) => (
      <option
        key={option}
        value={option}
      >
        {I18n.t(`form_item.skip_logic_options.${option}`)}
      </option>
    ));
  }

  render() {
    const { skip, type } = this.state;
    const selectProps = {
      className: 'form-control skip-or-not',
      value: skip,
      onChange: this.skipOptionChanged,
      name: `${type}[skip_if]`,
      id: `${type}_skip_logic`,
    };

    return (
      <div>
        <select {...selectProps}>
          {this.skipOptionTags()}
        </select>
        <SkipRuleSetFormField
          hide={skip === 'dont_skip'}
          {...this.props}
        />
      </div>
    );
  }
}

export default SkipLogicFormField;
