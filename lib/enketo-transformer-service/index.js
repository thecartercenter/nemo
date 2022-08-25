const transformer = require('enketo-transformer');

async function transform() {
  // Parse command-line arguments.
  const args = process.argv.slice(2);
  const xform = args[0];

  // See https://github.com/enketo/enketo-transformer for more info.
  const enketoFormObj = await transformer.transform({
    // required string of XForm
    xform,

    // optional string, to add theme if no theme is defined in the XForm
    // theme: '',

    // optional map, to replace jr://..../myfile.png URLs
    // media: {
    //   'myfile.png': '/path/to/somefile.png',
    // },

    // optional ability to disable markdown rendering (default is true)
    // markdown: true,

    // optional preprocess function that transforms the XForm (as libXMLJs object) to
    // e.g. correct incompatible XForm syntax before Enketo's transformation takes place
    // preprocess: (doc) => doc,
  });

  return enketoFormObj;
}

// Print the result to the terminal for someone else to consume.
transform().then((result) => {
  // Output raw (note console.log is only meant for debugging and truncates very long strings).
  process.stdout.write(JSON.stringify(result));
  process.stdout.write('\n');
});
