const transformer = require('enketo-transformer');

async function transform() {
  let xform = `<?xml version="1.0" encoding="UTF-8"?>
<h:html xmlns="http://www.w3.org/2002/xforms" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:h="http://www.w3.org/1999/xhtml" xmlns:jr="http://openrosa.org/javarosa" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <h:head>
    <h:title>2022 skip logic</h:title>
    <model>
      <instance>
        <data id="03965969-fd46-4732-a114-024eedc79275" version="2022021000">
          <qinga4be8a6f-5994-4b9c-9b2a-421ae7bd4257/>
          <qinga6c4c67e-737c-4e5a-bbc1-e94bf00e3a2d/>
          <qing3fd020a4-bcda-4c64-bc58-0fb2e4e7bbe3/>
          <qingfb7f48ba-6e12-4410-853b-903e564c4e28/>
          <qingcd363969-5bdc-416a-9bb1-e14f7fa3619a/>
          <qing1dd29e49-f2cf-4af7-bd89-0034f14b543b/>
          <qing59fbe142-48b4-4181-bf7a-72acbdf40304/>
        </data>
      </instance>
      <itext>
        <translation lang="English">
          <text id="qinga4be8a6f-5994-4b9c-9b2a-421ae7bd4257:label">
            <value>Text?</value>
          </text>
          <text id="qinga4be8a6f-5994-4b9c-9b2a-421ae7bd4257:hint">
            <value/>
          </text>
          <text id="qinga6c4c67e-737c-4e5a-bbc1-e94bf00e3a2d:label">
            <value>Location</value>
          </text>
          <text id="qinga6c4c67e-737c-4e5a-bbc1-e94bf00e3a2d:hint">
            <value/>
          </text>
          <text id="qing3fd020a4-bcda-4c64-bc58-0fb2e4e7bbe3:label">
            <value>Image</value>
            <value form="image">jr://images/88929e2d-79aa-48b8-a58b-4a6e2f8775df_media_prompt.png
            </value>
          </text>
          <text id="qing3fd020a4-bcda-4c64-bc58-0fb2e4e7bbe3:hint">
            <value/>
          </text>
          <text id="qingfb7f48ba-6e12-4410-853b-903e564c4e28:label">
            <value>Text Option</value>
          </text>
          <text id="qingfb7f48ba-6e12-4410-853b-903e564c4e28:hint">
            <value/>
          </text>
          <text id="qingcd363969-5bdc-416a-9bb1-e14f7fa3619a:label">
            <value>asdf</value>
          </text>
          <text id="qingcd363969-5bdc-416a-9bb1-e14f7fa3619a:hint">
            <value/>
          </text>
          <text id="qing1dd29e49-f2cf-4af7-bd89-0034f14b543b:label">
            <value>Q3 text</value>
          </text>
          <text id="qing1dd29e49-f2cf-4af7-bd89-0034f14b543b:hint">
            <value/>
          </text>
          <text id="qing59fbe142-48b4-4181-bf7a-72acbdf40304:label">
            <value>Text again</value>
          </text>
          <text id="qing59fbe142-48b4-4181-bf7a-72acbdf40304:hint">
            <value/>
          </text>
          <text id="on6c8df343-852e-4749-86e6-3ff59e0cb11d">
            <value>Oui</value>
          </text>
          <text id="onbd2f4b7a-2fa1-4eaf-9ab3-018f49f94d9d">
            <value>Non</value>
          </text>
          <text id="BLANK">
            <value/>
          </text>
        </translation>
        <translation lang="Français">
          <text id="qinga4be8a6f-5994-4b9c-9b2a-421ae7bd4257:label">
            <value>Text?</value>
          </text>
          <text id="qinga4be8a6f-5994-4b9c-9b2a-421ae7bd4257:hint">
            <value/>
          </text>
          <text id="qinga6c4c67e-737c-4e5a-bbc1-e94bf00e3a2d:label">
            <value>Location</value>
          </text>
          <text id="qinga6c4c67e-737c-4e5a-bbc1-e94bf00e3a2d:hint">
            <value/>
          </text>
          <text id="qing3fd020a4-bcda-4c64-bc58-0fb2e4e7bbe3:label">
            <value>Image</value>
            <value form="image">jr://images/88929e2d-79aa-48b8-a58b-4a6e2f8775df_media_prompt.png
            </value>
          </text>
          <text id="qing3fd020a4-bcda-4c64-bc58-0fb2e4e7bbe3:hint">
            <value/>
          </text>
          <text id="qingfb7f48ba-6e12-4410-853b-903e564c4e28:label">
            <value>Text Option</value>
          </text>
          <text id="qingfb7f48ba-6e12-4410-853b-903e564c4e28:hint">
            <value/>
          </text>
          <text id="qingcd363969-5bdc-416a-9bb1-e14f7fa3619a:label">
            <value>asdf</value>
          </text>
          <text id="qingcd363969-5bdc-416a-9bb1-e14f7fa3619a:hint">
            <value/>
          </text>
          <text id="qing1dd29e49-f2cf-4af7-bd89-0034f14b543b:label">
            <value>Q3 text</value>
          </text>
          <text id="qing1dd29e49-f2cf-4af7-bd89-0034f14b543b:hint">
            <value/>
          </text>
          <text id="qing59fbe142-48b4-4181-bf7a-72acbdf40304:label">
            <value>Text again</value>
          </text>
          <text id="qing59fbe142-48b4-4181-bf7a-72acbdf40304:hint">
            <value/>
          </text>
          <text id="on6c8df343-852e-4749-86e6-3ff59e0cb11d">
            <value>Oui</value>
          </text>
          <text id="onbd2f4b7a-2fa1-4eaf-9ab3-018f49f94d9d">
            <value>Non</value>
          </text>
          <text id="BLANK">
            <value/>
          </text>
        </translation>
      </itext>
      <bind nodeset="/data/qinga4be8a6f-5994-4b9c-9b2a-421ae7bd4257" type="string"/>
      <bind nodeset="/data/qinga6c4c67e-737c-4e5a-bbc1-e94bf00e3a2d" relevant="(not((/data/qinga4be8a6f-5994-4b9c-9b2a-421ae7bd4257 = 'skip'))) and (not((/data/qinga4be8a6f-5994-4b9c-9b2a-421ae7bd4257 = 'end')))" type="geopoint"/>
      <bind nodeset="/data/qing3fd020a4-bcda-4c64-bc58-0fb2e4e7bbe3" relevant="(not((/data/qinga4be8a6f-5994-4b9c-9b2a-421ae7bd4257 = 'skip'))) and (not((/data/qinga4be8a6f-5994-4b9c-9b2a-421ae7bd4257 = 'end')))" type="binary"/>
      <bind nodeset="/data/qingfb7f48ba-6e12-4410-853b-903e564c4e28" relevant="(not((/data/qinga4be8a6f-5994-4b9c-9b2a-421ae7bd4257 = 'skip'))) and (not((/data/qinga4be8a6f-5994-4b9c-9b2a-421ae7bd4257 = 'end')))" type="select1"/>
      <bind nodeset="/data/qingcd363969-5bdc-416a-9bb1-e14f7fa3619a" relevant="(not((/data/qinga4be8a6f-5994-4b9c-9b2a-421ae7bd4257 = 'skip'))) and (not((/data/qinga4be8a6f-5994-4b9c-9b2a-421ae7bd4257 = 'end')))" type="string"/>
      <bind nodeset="/data/qing1dd29e49-f2cf-4af7-bd89-0034f14b543b" relevant="(not((/data/qinga4be8a6f-5994-4b9c-9b2a-421ae7bd4257 = 'end')))" type="string"/>
      <bind nodeset="/data/qing59fbe142-48b4-4181-bf7a-72acbdf40304" relevant="(not((/data/qinga4be8a6f-5994-4b9c-9b2a-421ae7bd4257 = 'end')))" type="string"/>
    </model>
  </h:head>
  <h:body>
    <input ref="/data/qinga4be8a6f-5994-4b9c-9b2a-421ae7bd4257">
      <label ref="jr:itext('qinga4be8a6f-5994-4b9c-9b2a-421ae7bd4257:label')"/>
      <hint ref="jr:itext('qinga4be8a6f-5994-4b9c-9b2a-421ae7bd4257:hint')"/>
    </input>
    <input ref="/data/qinga6c4c67e-737c-4e5a-bbc1-e94bf00e3a2d">
      <label ref="jr:itext('qinga6c4c67e-737c-4e5a-bbc1-e94bf00e3a2d:label')"/>
      <hint ref="jr:itext('qinga6c4c67e-737c-4e5a-bbc1-e94bf00e3a2d:hint')"/>
    </input>
    <upload mediatype="image/*" ref="/data/qing3fd020a4-bcda-4c64-bc58-0fb2e4e7bbe3">
      <label ref="jr:itext('qing3fd020a4-bcda-4c64-bc58-0fb2e4e7bbe3:label')"/>
      <hint ref="jr:itext('qing3fd020a4-bcda-4c64-bc58-0fb2e4e7bbe3:hint')"/>
    </upload>
    <select1 ref="/data/qingfb7f48ba-6e12-4410-853b-903e564c4e28">
      <label ref="jr:itext('qingfb7f48ba-6e12-4410-853b-903e564c4e28:label')"/>
      <hint ref="jr:itext('qingfb7f48ba-6e12-4410-853b-903e564c4e28:hint')"/>
      <item>
        <label ref="jr:itext('on6c8df343-852e-4749-86e6-3ff59e0cb11d')"/>
        <value>on6c8df343-852e-4749-86e6-3ff59e0cb11d</value>
      </item>
      <item>
        <label ref="jr:itext('onbd2f4b7a-2fa1-4eaf-9ab3-018f49f94d9d')"/>
        <value>onbd2f4b7a-2fa1-4eaf-9ab3-018f49f94d9d</value>
      </item>
    </select1>
    <input ref="/data/qingcd363969-5bdc-416a-9bb1-e14f7fa3619a" rows="5">
      <label ref="jr:itext('qingcd363969-5bdc-416a-9bb1-e14f7fa3619a:label')"/>
      <hint ref="jr:itext('qingcd363969-5bdc-416a-9bb1-e14f7fa3619a:hint')"/>
    </input>
    <input ref="/data/qing1dd29e49-f2cf-4af7-bd89-0034f14b543b">
      <label ref="jr:itext('qing1dd29e49-f2cf-4af7-bd89-0034f14b543b:label')"/>
      <hint ref="jr:itext('qing1dd29e49-f2cf-4af7-bd89-0034f14b543b:hint')"/>
    </input>
    <input ref="/data/qing59fbe142-48b4-4181-bf7a-72acbdf40304">
      <label ref="jr:itext('qing59fbe142-48b4-4181-bf7a-72acbdf40304:label')"/>
      <hint ref="jr:itext('qing59fbe142-48b4-4181-bf7a-72acbdf40304:hint')"/>
    </input>
  </h:body>
</h:html>
`;

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
