const transformer = require('enketo-transformer');

async function transform() {
  const args = process.argv.slice(2);
  const xform = args[0];

  const transformedObj = await transformer.transform({
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

  return transformedObj;
}

// Print the result for someone else to consume.
transform().then((result) => console.log(result));
