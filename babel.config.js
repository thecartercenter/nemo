module.exports = function (api) {
  const validEnv = ['development', 'test', 'production'];
  const currentEnv = api.env();

  if (!validEnv.includes(currentEnv)) {
    throw new Error(
      `${'Please specify a valid `NODE_ENV` or '
      + '`BABEL_ENV` environment variables. Valid values are "development", '
      + '"test", and "production". Instead, received: '}${
        JSON.stringify(currentEnv)
      }.`,
    );
  }

  return {
    env: {
      production: {
        presets: [
          [
            '@babel/env',
            {
              modules: false,
              targets: {
                browsers: '> 1%',
                uglify: true,
              },
              useBuiltIns: 'entry',
            },
          ],
          '@babel/react',
        ],
        plugins: [
          '@babel/syntax-dynamic-import',
          '@babel/transform-runtime',
          '@babel/plugin-proposal-object-rest-spread',
          [
            '@babel/plugin-proposal-decorators',
            {
              legacy: true,
            },
          ],
          [
            '@babel/plugin-proposal-class-properties',
            {
              loose: true,
            },
          ],
        ],
      },
      development: {
        presets: [
          [
            '@babel/env',
            {
              modules: false,
              targets: {
                browsers: '> 1%',
                uglify: true,
              },
              useBuiltIns: 'entry',
            },
          ],
          '@babel/react',
        ],
        plugins: [
          '@babel/syntax-dynamic-import',
          '@babel/transform-runtime',
          '@babel/plugin-proposal-object-rest-spread',
          [
            '@babel/plugin-proposal-decorators',
            {
              legacy: true,
            },
          ],
          [
            '@babel/plugin-proposal-class-properties',
            {
              loose: true,
            },
          ],
        ],
      },
      test: {
        presets: [
          [
            '@babel/env',
            {
              targets: {
                browsers: '> 1%',
                uglify: true,
              },
              useBuiltIns: 'entry',
            },
          ],
          '@babel/react',
        ],
        plugins: [
          '@babel/syntax-dynamic-import',
          '@babel/transform-runtime',
          '@babel/plugin-proposal-object-rest-spread',
          [
            '@babel/plugin-proposal-decorators',
            {
              legacy: true,
            },
          ],
          [
            '@babel/plugin-proposal-class-properties',
            {
              loose: true,
            },
          ],
        ],
      },
    },
  };
};
