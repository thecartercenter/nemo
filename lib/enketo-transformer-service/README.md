# Enketo transformer service for NEMO

## Bird's eye overview

resources:
- [enketo-core github](https://github.com/enketo/enketo/tree/main/packages/enketo-core)
- [enketo-transformer github](https://github.com/enketo/enketo/blob/main/packages/enketo-transformer)

architecture/flow:
- nemo talks to `lib/enketo-transformer-service/index.js` (separate node app that runs enketo-transformer) to convert our form XML into a JSON object we're able to send to enketo
- nemo renders a `<div id="enketo">` in `enketo_form.html.erb`
- nemo injects 2 variables into JS via a `<script>` tag:
  - `window.ENKETO_MODEL_STR` is the form XML from enketo-transformer-service
  - `window.ENKETO_INSTANCE_STR` is the optional response XML (when editing)
- enketo injects itself into `document.querySelector('#enketo form')` via jQuery in `packs/enketo.js`
- enketo loads the two variables set above and renders the form
- user types in info and hits submit
- enketo submits XML to nemo's existing ODK `/submission` (`responses#create`) route
- on edit, nemo saves the edited XML to `modified_odk_xml` attachment so as to preserve the original `odk_xml` as required by some orgs

## Troubleshooting

If you get errors trying to `yarn install`:
- Make sure you are using the correct node version: the one specified in [../../.nvmrc](.nvmrc)
- Try explicitly specifying the C++ compiler used by Enketo dependencies: `yarn install -std=c++17`
