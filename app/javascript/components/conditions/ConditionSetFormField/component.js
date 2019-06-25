import React from 'react';
import PropTypes from 'prop-types';
import { inject, observer } from 'mobx-react';

import ConditionFormField from './ConditionFormField/component';

@inject('conditionSetStore')
@observer
class ConditionSetFormField extends React.Component {
  static propTypes = {
    conditionSetStore: PropTypes.object,
  };

  render() {
    const { conditionSetStore } = this.props;
    const { conditions, hide } = conditionSetStore;

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
      </div>
    );
  }
}

export default ConditionSetFormField;
