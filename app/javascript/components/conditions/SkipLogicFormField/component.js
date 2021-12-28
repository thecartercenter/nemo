import React from 'react';
import PropTypes from 'prop-types';

import SkipRuleFormField from './SkipRuleFormField';

class SkipLogicFormField extends React.Component {
  static propTypes = {
    type: PropTypes.string.isRequired,
    skipRules: PropTypes.arrayOf(PropTypes.object).isRequired,
    formId: PropTypes.string.isRequired,
    laterItems: PropTypes.arrayOf(PropTypes.object),
    refableQings: PropTypes.arrayOf(PropTypes.object),
  };

  constructor(props) {
    super(props);
    const { skipRules } = this.props;
    const skip = skipRules.length === 0 ? 'dont_skip' : 'skip';
    this.state = { skip, skipRules };
  }

  handleAddClick = () => {
    const { laterItems } = this.props;
    const laterItemsExist = laterItems.length > 0;
    this.setState(({ skipRules }) => ({
      skipRules: skipRules.concat([{
        key: Math.round(Math.random() * 100000000),
        destination: laterItemsExist ? 'item' : 'end',
        skipIf: 'always',
        conditions: [],
      }]),
    }));
  };

  skipOptionChanged = (event) => {
    const { skipRules } = this.state;
    this.setState({ skip: event.target.value });
    if (event.target.value === 'skip' && skipRules.length === 0) {
      this.handleAddClick();
    }
  };

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
  };

  render() {
    const { formId, laterItems, type, refableQings } = this.props;
    const { skip, skipRules } = this.state;
    const selectProps = {
      className: 'form-control skip-or-not',
      value: skip,
      onChange: this.skipOptionChanged,
      name: `${type}[skip_logic]`,
      id: `${type}_skip_logic`,
    };

    return (
      <div className="skip-logic-container">
        <select {...selectProps}>
          {this.skipOptionTags()}
        </select>
        <div
          className="rule-set"
          style={{ display: skip === 'dont_skip' ? 'none' : '' }}
        >
          {skipRules.map((rule, index) => (
            <SkipRuleFormField
              formId={formId}
              hide={skip === 'dont_skip'}
              key={rule.key || rule.id}
              laterItems={laterItems}
              ruleId={`rule-${index + 1}`}
              namePrefix={`${type}[skip_rules_attributes][${index}]`}
              refableQings={refableQings}
              {...rule}
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

export default SkipLogicFormField;
