import { Form } from 'enketo-core';

// Simply include this script and Enketo will be rendered
// directly in the including page's DOM.
//
// See https://enketo.github.io/enketo-core/tutorial-00-getting-started.html
// for more details.
async function inject() {
  // required HTML Form DOM element
  const formEl = document.querySelector('#enketo form');

  // required object containing data for the form
  const data = {
    // required string of the default instance defined in the XForm
    modelStr: window.ENKETO_MODEL_STR,
    // optional string of an existing instance to be edited
    instanceStr: window.ENKETO_INSTANCE_STR,
    // optional boolean whether this instance has ever been submitted before
    submitted: false,
    // optional array of external data objects containing:
    // {id: 'someInstanceId', xml: XMLDocument}
    external: [],
    // optional object of session properties
    // 'deviceid', 'username', 'email', 'phonenumber', 'simserial', 'subscriberid'
    session: {},
  };

  // Form-specific configuration
  const options = {
    // if true or not set at all, printing the form only includes what is visible.
    printRelevantOnly: true,
    // optional default language. required in nemo since we hide the enketo language picker.
    language: window.ENKETO_DEFAULT_LANG,
  };

  // Instantiate a form
  const form = new Form(formEl, data, options);

  // Initialize the form and capture any load errors
  // TODO: Handle errors more gracefully
  const loadErrors = form.init();
  if (loadErrors.length > 0) {
    console.error('NEMO encountered Enketo loadErrors:', loadErrors);
  }

  // If desired, scroll to a specific question with any XPath location expression,
  // and aggregate any loadErrors.
  // loadErrors = loadErrors.concat(form.goTo('//repeat[3]/node'));

  $('#enketo-submit').on('click', async () => {
    // clear non-relevant questions and validate
    const valid = await form.validate();

    if (!valid) {
      // TODO: Convert to a less-intrusive DOM element
      alert('Form contains errors. Please see fields marked in red.');
    } else {
      // Record is valid!
      ELMO.app.loading(true);

      // Convert string into a file to upload, like NEMO expects from Collect;
      // adapted from https://stackoverflow.com/a/34340245/763231.
      const xml = form.getDataStr();
      const formData = new FormData();
      formData.append('xml_submission_file', new File([new Blob([xml])], 'submission.xml'));

      const editingResponse = $('#enketo-submit').data('responseShortcode');

      $.ajax({
        url: submissionUrl(editingResponse),
        method: editingResponse ? 'put' : 'post',
        data: formData,
        processData: false,
        contentType: false,
        success: (_data, _status, { status, statusText, responseJSON }) => {
          // These will be empty on NEW submission, but present on EDIT.
          const { msg, redirect } = responseJSON || {};

          console.log({ status, statusText, msg, redirect });

          // Timeout is messy test logic for rspec to reliably detect the loading indicator.
          const timeout = process.env.RAILS_ENV === 'test' ? 100 : 0;
          setTimeout(() => {
            ELMO.app.loading(false); // Dismiss the load indicator BEFORE redirecting otherwise rspec gets confused.
            window.location.href = redirect || ELMO.app.url_builder.build('responses');
          }, timeout);
        },
        error: ({ status, statusText, responseJSON }) => {
          // TODO: Convert to a less-intrusive DOM element
          alert(`Error submitting form: ${status} ${statusText}`);

          // TODO: Handle errors more gracefully
          console.log({ error: responseJSON.error });
        },
        always: () => {
          ELMO.app.loading(false);
        },
      });
    }
  });
}

function submissionUrl(editingResponse) {
  const base = editingResponse
    ? ELMO.app.url_builder.build('submission', editingResponse)
    : ELMO.app.url_builder.build('submission');
  return `${base}?enketo=1`;
}

// Run the async method automatically.
inject();
