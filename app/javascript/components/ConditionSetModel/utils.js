import ConditionSetModel from './ConditionSetModel';

/** Cache. */
const conditionSetStores = {};

/**
 * Returns a new instance of ConditionSetModel.
 *
 * Generally this should be added to a top-level Provider and used
 * once per condition set.
 */
export function provideConditionSetStore(uniqueId) {
  if (!conditionSetStores[uniqueId]) {
    conditionSetStores[uniqueId] = new ConditionSetModel();

    if (process.env.NODE_ENV === 'development') {
      // Debug helper.
      window.store = window.store || {};
      window.store[uniqueId] = conditionSetStores[uniqueId];
    }
  }

  return conditionSetStores[uniqueId];
}
