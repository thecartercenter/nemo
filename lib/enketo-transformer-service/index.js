const transformer = require('enketo-transformer');

async function transform() {
  let xform = `<?xml version="1.0" encoding="UTF-8"?>
<h:html xmlns="http://www.w3.org/2002/xforms" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:h="http://www.w3.org/1999/xhtml" xmlns:jr="http://openrosa.org/javarosa" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <h:head>
    <h:title>Groups simple + conditions</h:title>
    <model>
      <instance>
        <data id="a1e06993-2754-4527-843f-7a3364f2a6d8" version="2021040700">
          <grp7f158462-7481-4813-ba04-695c336ce887>
            <header/>
            <grpdc53f6fd-932c-40b3-82f1-bb8f2318610a jr:template="">
              <header/>
              <qing52a4805c-82e2-462a-ab3e-7a417132c774/>
            </grpdc53f6fd-932c-40b3-82f1-bb8f2318610a>
          </grp7f158462-7481-4813-ba04-695c336ce887>
          <qing20558ca9-2d34-44d4-a230-e7c14c770919/>
          <qinga25289e5-e5b5-4fd3-9621-dd1bdc4512fa/>
        </data>
      </instance>
      <itext>
        <translation lang="English">
          <text id="grp7f158462-7481-4813-ba04-695c336ce887:label">
            <value>G1</value>
          </text>
          <text id="grp7f158462-7481-4813-ba04-695c336ce887:hint">
            <value/>
          </text>
          <text id="grpdc53f6fd-932c-40b3-82f1-bb8f2318610a:label">
            <value>R1</value>
          </text>
          <text id="grpdc53f6fd-932c-40b3-82f1-bb8f2318610a:hint">
            <value/>
          </text>
          <text id="qing52a4805c-82e2-462a-ab3e-7a417132c774:label">
            <value>Text</value>
          </text>
          <text id="qing52a4805c-82e2-462a-ab3e-7a417132c774:hint">
            <value/>
          </text>
          <text id="qing20558ca9-2d34-44d4-a230-e7c14c770919:label">
            <value>Text</value>
          </text>
          <text id="qing20558ca9-2d34-44d4-a230-e7c14c770919:hint">
            <value/>
          </text>
          <text id="qinga25289e5-e5b5-4fd3-9621-dd1bdc4512fa:label">
            <value>Date?</value>
          </text>
          <text id="qinga25289e5-e5b5-4fd3-9621-dd1bdc4512fa:hint">
            <value/>
          </text>
          <text id="qinga25289e5-e5b5-4fd3-9621-dd1bdc4512fa:constraintMsg">
            <value>Valid only if: [TextQ2] is not equal to &quot;date&quot;</value>
          </text>
          <text id="BLANK">
            <value/>
          </text>
        </translation>
      </itext>
      <bind nodeset="/data/grp7f158462-7481-4813-ba04-695c336ce887"/>
      <bind nodeset="/data/grp7f158462-7481-4813-ba04-695c336ce887/header" readonly="true()" type="string"/>
      <bind nodeset="/data/grp7f158462-7481-4813-ba04-695c336ce887/grpdc53f6fd-932c-40b3-82f1-bb8f2318610a"/>
      <bind nodeset="/data/grp7f158462-7481-4813-ba04-695c336ce887/grpdc53f6fd-932c-40b3-82f1-bb8f2318610a/header" readonly="true()" type="string"/>
      <bind nodeset="/data/grp7f158462-7481-4813-ba04-695c336ce887/grpdc53f6fd-932c-40b3-82f1-bb8f2318610a/qing52a4805c-82e2-462a-ab3e-7a417132c774" type="string"/>
      <bind nodeset="/data/qing20558ca9-2d34-44d4-a230-e7c14c770919" type="string"/>
      <bind constraint="((/data/qing20558ca9-2d34-44d4-a230-e7c14c770919 != 'date'))" jr:constraintMsg="jr:itext('qinga25289e5-e5b5-4fd3-9621-dd1bdc4512fa:constraintMsg')" nodeset="/data/qinga25289e5-e5b5-4fd3-9621-dd1bdc4512fa" relevant="((/data/qing20558ca9-2d34-44d4-a230-e7c14c770919 = 'date'))" required="true()" type="date"/>
    </model>
  </h:head>
  <h:body>
    <group ref="/data/grp7f158462-7481-4813-ba04-695c336ce887">
      <label ref="jr:itext('grp7f158462-7481-4813-ba04-695c336ce887:label')"/>
      <group ref="/data/grp7f158462-7481-4813-ba04-695c336ce887/grpdc53f6fd-932c-40b3-82f1-bb8f2318610a">
        <label ref="jr:itext('grpdc53f6fd-932c-40b3-82f1-bb8f2318610a:label')"/>
        <repeat nodeset="/data/grp7f158462-7481-4813-ba04-695c336ce887/grpdc53f6fd-932c-40b3-82f1-bb8f2318610a">
          <group appearance="field-list">
            <input ref="/data/grp7f158462-7481-4813-ba04-695c336ce887/grpdc53f6fd-932c-40b3-82f1-bb8f2318610a/qing52a4805c-82e2-462a-ab3e-7a417132c774">
              <label ref="jr:itext('qing52a4805c-82e2-462a-ab3e-7a417132c774:label')"/>
              <hint ref="jr:itext('qing52a4805c-82e2-462a-ab3e-7a417132c774:hint')"/>
            </input>
          </group>
        </repeat>
      </group>
    </group>
    <input ref="/data/qing20558ca9-2d34-44d4-a230-e7c14c770919">
      <label ref="jr:itext('qing20558ca9-2d34-44d4-a230-e7c14c770919:label')"/>
      <hint ref="jr:itext('qing20558ca9-2d34-44d4-a230-e7c14c770919:hint')"/>
    </input>
    <input ref="/data/qinga25289e5-e5b5-4fd3-9621-dd1bdc4512fa">
      <label ref="jr:itext('qinga25289e5-e5b5-4fd3-9621-dd1bdc4512fa:label')"/>
      <hint ref="jr:itext('qinga25289e5-e5b5-4fd3-9621-dd1bdc4512fa:hint')"/>
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
