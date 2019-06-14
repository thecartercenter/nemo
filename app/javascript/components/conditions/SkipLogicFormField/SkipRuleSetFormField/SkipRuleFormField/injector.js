import React from 'react';
import PropTypes from 'prop-types';
import { Provider } from 'mobx-react';

import { provideConditionSetStore } from '../../../ConditionSetFormField/utils';
import SkipRuleFormField from './component';

/**
 * Provides any needed stores to its children.
 */
function Injector(props) {
  const {
    ruleId,
    formId,
    namePrefix,
    conditions,
    id,
    refableQings,
    skipIf,
  } = props;

  // eslint-disable-next-line react/prop-types, react/destructuring-assignment
  const conditionSetStore = provideConditionSetStore(`skip-${ruleId}`, {
    formId,
    namePrefix: `${namePrefix}[conditions_attributes]`,
    conditions,
    conditionableId: id,
    conditionableType: 'SkipRule',
    refableQings,
    hide: skipIf === 'always',
  });

  return (
    <Provider conditionSetStore={conditionSetStore}>
      <SkipRuleFormField {...props} />
    </Provider>
  );
}

Injector.propTypes = {
  ruleId: PropTypes.string.isRequired,
  namePrefix: PropTypes.string.isRequired,

  // TODO: Describe these prop types.
  /* eslint-disable react/forbid-prop-types */
  formId: PropTypes.any,
  conditions: PropTypes.any,
  id: PropTypes.any,
  refableQings: PropTypes.any,
  skipIf: PropTypes.any,
  /* eslint-enable */
};

export default Injector;
