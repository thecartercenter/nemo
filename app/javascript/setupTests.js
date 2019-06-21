import Enzyme from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';
import I18n from 'i18n-js';

// Stub out jquery.
window.$ = () => {};
window.$.ajax = () => ({});

window.ELMO = {
  app: {
    loading: jest.fn(),
    url_builder: {
      build: jest.fn(),
    },
  },
  Utils: {
    Select2OptionBuilder: class { ajax() { return { url: 'mock' }; } },
  },
};

// Stub out navigation features (otherwise jsdom complains).
delete window.location;
window.location = {
  assign: jest.fn(),
  pathname: '/pathname',
};

// Stub out Bootstrap components.
[
  'Button',
  'ButtonToolbar',
  'ButtonGroup',
  'OverlayTrigger',
  'Popover',
].forEach((name) => {
  jest.doMock(`react-bootstrap/${name}`, () => name);
});

jest.mock('react-bootstrap/Form', () => ({
  Label: () => 'Label',
}));

jest.mock('react-select2-wrapper/lib/components/Select2.full', () => 'Select2');
jest.mock('react-select2-wrapper/css/select2.css', () => undefined);

// Provide translations.
window.I18n = I18n;

try {
  require('../assets/javascripts/i18n/translations');
} catch (error) {
  // eslint-disable-next-line no-console
  console.error('Failed to find translations. Did you run `rails i18n:js:export` yet?');
}

// Initialize Enzyme.
Enzyme.configure({
  adapter: new Adapter(),
});
