import React from 'react';
import PropTypes from 'prop-types';

import SkipRuleFormField from './SkipRuleFormField';

class SkipRuleSetFormField extends React.Component {
  constructor(props) {
    super(props);
    this.state = props;
    this.handleAddClick = this.handleAddClick.bind(this);
  }

  // If about to show the set and it's empty, add a blank one.
  componentWillReceiveProps(newProps) {
    const { hide } = this.props;
    const { skipRules } = this.state;
    if (!newProps.hide && hide && skipRules.length === 0) {
      this.handleAddClick();
    }
  }

  handleAddClick() {
    const { laterItems } = this.state;
    const laterItemsExist = laterItems.length > 0;
    this.setState((curState) => ({ skipRules:
      curState.skipRules.concat([{
        key: Math.round(Math.random() * 100000000),
        destination: laterItemsExist ? 'item' : 'end',
        skipIf: 'always',
        conditions: [],
      }]) }));
  }

  render() {
    const { hide } = this.props;
    const { skipRules, formId, laterItems, type, refableQings } = this.state;
    return (
      <div
        className="skip-rule-set"
        style={{ display: hide ? 'none' : '' }}
      >
        {skipRules.map((props, index) => (
          <SkipRuleFormField
            formId={formId}
            hide={hide}
            key={props.key || props.id}
            laterItems={laterItems}
            ruleId={`rule-${index + 1}`}
            namePrefix={`${type}[skip_rules_attributes][${index}]`}
            refableQings={refableQings}
            {...props}
          />
        ))}
        <div
          className="skip-rule-add-link-wrapper"
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
    );
  }
}

SkipRuleSetFormField.propTypes = {
  hide: PropTypes.bool.isRequired,
};

export default SkipRuleSetFormField;
