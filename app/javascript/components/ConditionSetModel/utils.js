import ConditionSetModel from './ConditionSetModel';

/**
 * Returns a new instance of ConditionSetModel.
 *
 * Generally this should be added to a top-level Provider and created
 * once per condition set.
 */
export function createConditionSetStore(debugName) {
  const store = new ConditionSetModel();

  if (process.env.NODE_ENV === 'development') {
    // Debug helper.
    window.store = window.store || {};
    if (window.store[debugName]) {
      console.warn('WARN: Trying to create store that already exists:', debugName);
    }
    window.store[debugName] = store;
  }

  return store;
}
