import React from 'react';
import { Provider } from 'mobx-react';

import { provideConditionSetStore } from '../../../ConditionSetFormField/utils';
import SkipRuleFormField from './component';

/**
 * Provides any needed stores to its children.
 */
function Injector(props) {
  // eslint-disable-next-line react/prop-types, react/destructuring-assignment
  const conditionSetStore = provideConditionSetStore(`skip-${props.ruleId}`);

  return (
    <Provider conditionSetStore={conditionSetStore}>
      <SkipRuleFormField {...props} />
    </Provider>
  );
}

export default Injector;
