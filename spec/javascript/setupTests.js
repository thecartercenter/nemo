import Enzyme from "enzyme";
import Adapter from "enzyme-adapter-react-16";

Enzyme.configure({
  adapter: new Adapter(),
});

// Stub out i18n-js because it's not invoked in this environment.
// eslint-disable-next-line no-undef
window.I18n = {
  t: () => "[translated]",
};
