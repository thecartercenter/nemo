/**
 * Returns a new instance of ConditionSetModel.
 *
 * Generally this should be added to a top-level Provider and used
 * once per condition set.
 */
export function provideConditionSetStore(ConditionSetModel, uniqueId, initialState) {
  const store = new ConditionSetModel(initialState);

  if (process.env.NODE_ENV === 'development') {
    // Debug helper.
    window.store = window.store || {};
    window.store[uniqueId] = store;
  }

  return store;
}

/**
 * Return a map of { name: value } representing the current selections.
 */
export function getLevelsValues(levels) {
  return levels.reduce((reduction, { name, selected }) => {
    // eslint-disable-next-line no-param-reassign
    reduction[name] = selected;
    return reduction;
  }, {});
}

/**
 * Given a map of default { name: value },
 * apply `value` to each `name` level that has no value yet.
 */
export function applyDefaultLevelsValues(levels, defaultValues) {
  return levels.map((level) => {
    const { name, selected } = level;
    return {
      ...level,
      selected: defaultValues[name] || selected,
    };
  });
}
