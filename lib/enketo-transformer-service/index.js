const transformer = require('enketo-transformer');

async function transform() {
  let xform = `<?xml version="1.0"?>
  <h:html xmlns="http://www.w3.org/2002/xforms" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:h="http://www.w3.org/1999/xhtml" xmlns:jr="http://openrosa.org/javarosa" xmlns:orx="http://openrosa.org/xforms" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <h:head>
      <h:title>basic</h:title>
      <model>
        <instance>
          <basic id="basic">
            <height/>
          </basic>
        </instance>
        <bind nodeset="height" type="int"/>
      </model>
    </h:head>
    <h:body>
      <input ref="height">
        <label>what is your height</label>
      </input>
    </h:body>
  </h:html>`;

  let transformed = await transformer.transform({
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

  return transformed;
}

// Print the result for someone else to consume.
// console.log('test');
transform().then((result) => console.log(result))
