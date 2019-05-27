const mobxReact = require.requireActual('mobx-react');

module.exports = {
  ...mobxReact,
  inject: () => (Component) => Component,
};
