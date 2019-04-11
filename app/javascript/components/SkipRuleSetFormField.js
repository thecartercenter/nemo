import React from 'react';
import PropTypes from 'prop-types';

import SkipRuleFormField from './SkipRuleFormField';

class SkipRuleSetFormField extends React.Component {
  static propTypes = {
    hide: PropTypes.bool.isRequired,

    // TODO: Describe these prop types.
    /* eslint-disable react/forbid-prop-types */
    skipRules: PropTypes.any,
    formId: PropTypes.any,
    laterItems: PropTypes.any,
    type: PropTypes.any,
    refableQings: PropTypes.any,
    /* eslint-enable */
  };

  constructor(props) {
    super(props);
    const { skipRules, formId, laterItems, type, refableQings } = this.props;
    this.state = { skipRules, formId, laterItems, type, refableQings };
  }

  // If about to show the set and it's empty, add a blank one.
  componentWillReceiveProps(newProps) {
    const { hide } = this.props;
    const { skipRules } = this.state;
    if (!newProps.hide && hide && skipRules.length === 0) {
      this.handleAddClick();
    }
  }

  handleAddClick = () => {
    const { laterItems } = this.state;
    const laterItemsExist = laterItems.length > 0;
    this.setState(({ skipRules }) => ({
      skipRules: skipRules.concat([{
        key: Math.round(Math.random() * 100000000),
        destination: laterItemsExist ? 'item' : 'end',
        skipIf: 'always',
        conditions: [],
      }]),
    }));
  }

  render() {
    const { hide } = this.props;
    const { skipRules, formId, laterItems, type, refableQings } = this.state;

    // TODO: Listen for changes to update the store (not currently needed).
    return (
      <div
        className="skip-rule-set"
        style={{ display: hide ? 'none' : '' }}
      >
        {skipRules.map((rule, index) => (
          <SkipRuleFormField
            formId={formId}
            hide={hide}
            key={rule.key || rule.id}
            laterItems={laterItems}
            ruleId={`rule-${index + 1}`}
            namePrefix={`${type}[skip_rules_attributes][${index}]`}
            refableQings={refableQings}
            {...rule}
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

export default SkipRuleSetFormField;
