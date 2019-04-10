import React from 'react';
import PropTypes from 'prop-types';
import { inject, observer } from 'mobx-react';

import ConditionFormField from './ConditionFormField';

@inject('conditionSetStore')
@observer
class ConditionSetFormField extends React.Component {
  static propTypes = {
    conditionSetStore: PropTypes.object,
  };

  componentWillMount() {
    const { conditionSetStore } = this.props;
    const { hide } = conditionSetStore;
    if (!hide) {
      this.handleAddBlankCondition();
    }
  }

  componentWillReceiveProps(newProps) {
    // TODO: This logic no longer works because of synchronous updating.
    const { conditionSetStore: { hide: wasHidden } } = this.props;
    const { conditionSetStore: { hide: isHidden } } = newProps;
    if (wasHidden && !isHidden) {
      this.handleAddBlankCondition();
    }
  }

  // If about to show the set and it's empty, add a blank condition.
  handleAddBlankCondition = () => {
    const { conditionSetStore } = this.props;
    const { conditions } = conditionSetStore;
    if (conditions.length === 0) {
      this.handleAddClick();
    }
  }

  handleAddClick = () => {
    const { conditionSetStore } = this.props;
    const { conditions, formId, refableQings, conditionableId, conditionableType } = conditionSetStore;

    conditionSetStore.conditions = conditions.concat([{
      key: Math.round(Math.random() * 100000000),
      formId,
      refableQings,
      operatorOptions: [],
      conditionableId,
      conditionableType,
    }]);
  }

  render() {
    const { conditionSetStore } = this.props;
    const { conditions, namePrefix, hide } = conditionSetStore;

    return (
      <div
        className="condition-set"
        style={{ display: hide ? 'none' : '' }}
      >
        {conditions.map((props, index) => (
          <ConditionFormField
            hide={hide}
            index={index}
            key={props.key || props.id}
            namePrefix={namePrefix}
            {...props}
          />
        ))}
        {/* TODO: Improve a11y. */}
        {/* eslint-disable */}
        <a
          onClick={this.handleAddClick}
          tabIndex="0"
        >
        {/* eslint-enable */}
          <i className="fa fa-plus add-condition" />
          {' '}
          {I18n.t('form_item.add_condition')}
        </a>
      </div>
    );
  }
}

export default ConditionSetFormField;
