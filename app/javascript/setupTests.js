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
  // Provide minimal English translations for Jest runs without Rails export.
  I18n.locale = 'en';
  I18n.translations = I18n.translations || {};
  I18n.translations.en = {
    common: {
      search: 'Search',
      apply: 'Apply',
      _yes: 'Yes',
      _no: 'No',
      either: 'Either',
      startDatePlaceholder: 'Start Date',
      endDatePlaceholder: 'End Date',
      startDate: 'Start Date',
      endDate: 'End Date',
    },
    filter: {
      date: 'Date',
      form: 'Form',
      question: 'Question',
      reviewed: 'Reviewed',
      is_reviewed: "Is marked 'reviewed'",
      submitter: 'Submitter',
      choose_form: 'Choose a form',
      choose_submitter: {
        submitter: 'Choose a user',
        group: 'Choose a group',
      },
      search_box_placeholder: 'Search',
      showing_questions_from: 'Showing questions from %{form_list} only.',
    },
    condition: {
      left_qing_prompt: 'Choose question ...',
      right_side_type: {
        literal: 'A specific value ...',
        qing: 'Another question ...',
      },
    },
    // Intentionally omit search.help_title so snapshots still show missing translation
    skip_rule: {
      dest_prompt: 'Choose destination ...',
      skip_if_options: {},
    },
    form_item: {
      display_if_options: {},
      skip_logic_options: {
        end_of_form: 'End of form',
      },
      delete_rule: 'Delete rule',
      add_rule: 'Add rule',
    },
  };
}

// Initialize Enzyme.
Enzyme.configure({
  adapter: new Adapter(),
});
