import React from 'react';
import PropTypes from 'prop-types';
import { inject, observer } from 'mobx-react';

import ConditionFormField from '../ConditionFormField/ConditionFormField';

@inject('conditionSetStore')
@observer
class ConditionSetFormField extends React.Component {
  static propTypes = {
    conditionSetStore: PropTypes.object,
  };

  render() {
    const { conditionSetStore } = this.props;
    const { conditions, hide, handleAddClick } = conditionSetStore;

    return (
      <div
        className="condition-set"
        style={{ display: hide ? 'none' : '' }}
      >
        {conditions.map((condition, index) => (
          <ConditionFormField
            key={condition.key || condition.id}
            index={index}
            condition={condition}
          />
        ))}
        {/* TODO: Improve a11y. */}
        {/* eslint-disable */}
        <a
          onClick={handleAddClick}
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
