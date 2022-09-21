const { moduleExists } = require('@rails/webpacker')

// See also Ruby config/webpack/environment.js
//
// See docs at https://babeljs.io/docs/en/options
//
// Initialized based on default config from webpacker at
// https://github.com/rails/webpacker/blob/master/package/babel/preset.js
module.exports = function config(api) {
  const validEnv = ['development', 'test', 'production']
  const currentEnv = api.env()
  const isDevelopmentEnv = api.env('development')
  const isProductionEnv = api.env('production')
  const isTestEnv = api.env('test')

  if (!validEnv.includes(currentEnv)) {
    throw new Error(
      `Please specify a valid NODE_ENV or BABEL_ENV environment variable. Valid values are "development", "test", and "production". Instead, received: "${JSON.stringify(
        currentEnv
      )}".`
    )
  }

  return {
    presets: [
      isTestEnv && ['@babel/preset-env', { targets: { node: 'current' } }],
      (isProductionEnv || isDevelopmentEnv) && [
        '@babel/preset-env',
        {
          useBuiltIns: 'entry',
          corejs: '3.8',
          modules: 'auto',
          bugfixes: true,
          loose: true,
          exclude: ['transform-typeof-symbol']
        }
      ],
      moduleExists('@babel/preset-typescript') && [
        '@babel/preset-typescript',
        { allExtensions: true, isTSX: true }
      ]
    ].filter(Boolean),
    plugins: [
      ['@babel/plugin-transform-runtime', { helpers: false }]
    ].filter(Boolean)
  }
}
