const mobxReact = jest.requireActual('mobx-react');

module.exports = {
  ...mobxReact,
  inject: () => (Component) => Component,
};
