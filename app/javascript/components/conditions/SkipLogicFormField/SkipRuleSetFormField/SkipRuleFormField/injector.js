import React from 'react';
import { Provider } from 'mobx-react';

import { provideConditionSetStore } from '../../../ConditionSetFormField/utils';
import SkipRuleFormField from './component';

/**
 * Provides any needed stores to its children.
 */
const Injector = (props) => (
  // eslint-disable-next-line react/prop-types, react/destructuring-assignment
  <Provider conditionSetStore={provideConditionSetStore(`skip-${props.ruleId}`)}>
    <SkipRuleFormField {...props} />
  </Provider>
);

export default Injector;
