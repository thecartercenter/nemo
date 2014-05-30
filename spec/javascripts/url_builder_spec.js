describe('UrlBuilder', function() {

  var builder;

  describe('build', function() {

    describe('mission mode', function() {

      beforeEach(function() {
        builder = new ELMO.UrlBuilder({locale: 'en', mode: 'mission', mission_name: 'mission1'});
      });

      it('should maintain locale and mission', function() {
        expect(builder.build('a', 'b')).toEqual('/en/m/mission1/a/b');
      });

      it('should work with single slash', function() {
        expect(builder.build('/')).toEqual('/en/m/mission1');
      });

      it('should discard blank components', function() {
        expect(builder.build('a', '', 'b', '')).toEqual('/en/m/mission1/a/b');
      });

      it('should accept a new locale and mission', function() {
        expect(builder.build('a', 'b', {locale: 'fr', mission_name: 'mission2'})).toEqual('/fr/m/mission2/a/b');
      });

      it('should accept a new mode', function() {
        expect(builder.build('a', 'b', {locale: 'fr', mode: 'admin'})).toEqual('/fr/admin/a/b');
      });

      it('should replace old locale and mission', function() {
        expect(builder.build('/en/m/mission1/a/b', {locale: 'fr', mission_name: 'mission2'})).toEqual('/fr/m/mission2/a/b');
      });
    });

    describe('admin mode', function() {

      beforeEach(function() {
        builder = new ELMO.UrlBuilder({locale: 'en', mode: 'admin'});
      });

      it('should maintain locale and mode', function() {
        expect(builder.build('a', 'b')).toEqual('/en/admin/a/b');
      });

      it('should accept a new locale', function() {
        expect(builder.build('a', 'b', {locale: 'fr'})).toEqual('/fr/admin/a/b');
      });

      it('should accept basic mode', function() {
        expect(builder.build('a', 'b', {locale: 'fr', mode: 'basic'})).toEqual('/fr/a/b');
      });

      it('should replace old mode', function() {
        expect(builder.build('/en/admin/a/b', {locale: 'fr', mode: 'mission', mission_name: 'mission2'})).toEqual('/fr/m/mission2/a/b');
      });
    });

    describe('basic mode', function() {

      beforeEach(function() {
        builder = new ELMO.UrlBuilder({locale: 'en', mode: 'basic'});
      });

      it('should maintain locale and mode', function() {
        expect(builder.build('a', 'b')).toEqual('/en/a/b');
      });

      it('should work with single slash', function() {
        expect(builder.build('/')).toEqual('/en');
      });

      it('should accept a new locale', function() {
        expect(builder.build('a', 'b', {locale: 'fr'})).toEqual('/fr/a/b');
      });

      it('should accept a new mode', function() {
        expect(builder.build('a', 'b', {locale: 'fr', mode: 'admin'})).toEqual('/fr/admin/a/b');
      });

      it('should replace old mode', function() {
        expect(builder.build('/en/a/b', {locale: 'fr', mode: 'admin'})).toEqual('/fr/admin/a/b');
      });

    });

  });

  function expect_basic_strip_behavior(builder) {
    expect(builder.strip_scope('/en/foo')).toEqual('/foo');
    expect(builder.strip_scope('/en/foo/bar')).toEqual('/foo/bar');
    expect(builder.strip_scope('/foo')).toEqual('/foo');
    expect(builder.strip_scope('/en/')).toEqual('/');
    expect(builder.strip_scope('/en')).toEqual('/');
    expect(builder.strip_scope('/')).toEqual('/');
    expect(builder.strip_scope('')).toEqual('/');
  };

  describe('strip_scope', function() {

    describe('mission mode', function() {

      beforeEach(function() {
        builder = new ELMO.UrlBuilder({locale: 'en', mode: 'mission', mission_name: 'mission1'});
      });

      it('should strip properly', function() {
        expect_basic_strip_behavior(builder);
        expect(builder.strip_scope('/en/m/mission1/foo')).toEqual('/foo');
        expect(builder.strip_scope('/en/m/mission1')).toEqual('/');
        expect(builder.strip_scope('/en/m/mission1/')).toEqual('/');
      });

    });

    describe('admin mode', function() {

      beforeEach(function() {
        builder = new ELMO.UrlBuilder({locale: 'en', mode: 'admin'});
      });

      it('should strip properly', function() {
        expect_basic_strip_behavior(builder);
        expect(builder.strip_scope('/en/admin/foo')).toEqual('/foo');
        expect(builder.strip_scope('/en/admin')).toEqual('/');
        expect(builder.strip_scope('/en/admin/')).toEqual('/');
      });

    });

    describe('basic mode', function() {

      beforeEach(function() {
        builder = new ELMO.UrlBuilder({locale: 'en', mode: 'basic'});
      });

      it('should strip properly', function() {
        expect_basic_strip_behavior(builder);
      });

    });

  });

});
