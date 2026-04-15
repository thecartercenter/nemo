const ReactDOM = require('react-dom');

const createRoot = (domNode) => ({
  render(reactElement) {
    return ReactDOM.render(reactElement, domNode);
  },
  unmount() {
    return ReactDOM.unmountComponentAtNode(domNode);
  },
});

const hydrateRoot = (domNode, reactElement) => {
  ReactDOM.hydrate(reactElement, domNode);
  return createRoot(domNode);
};

module.exports = {
  createRoot,
  hydrateRoot,
};
