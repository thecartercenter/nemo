import React from 'react';
import PropTypes from 'prop-types';
import { Provider } from 'mobx-react';

import ConditionSetModel from '../../ConditionSetFormField/model';
import { provideConditionSetStore } from '../../ConditionSetFormField/utils';
import SkipRuleFormField from './component';

let forcedResetNonce = 0;

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
  const conditionSetStore = provideConditionSetStore(ConditionSetModel, `skip-${ruleId}`, {
    formId,
    namePrefix: `${namePrefix}[conditions_attributes]`,
    conditions,
    conditionableId: id,
    conditionableType: 'SkipRule',
    refableQings,
    hide: skipIf === 'always',
  });

  // eslint-disable-next-line no-return-assign
  return (
    <Provider key={forcedResetNonce += 1} conditionSetStore={conditionSetStore}>
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
