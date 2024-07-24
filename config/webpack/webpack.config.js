const { webpackConfig, merge } = require('shakapacker')

// webpackConfig.loaders.append('ignore', {
//   test: /\.test\.js$/,
//   loader: 'ignore-loader',
// });

module.exports = merge(
  webpackConfig,
  {
    rules: [
      {
        test: /\.test\.js$/,
        use: ['ignore-loader']
      },
      {
        test: /node_modules\/(enketo-core|openrosa-xpath-evaluator)\//,
        use: ['babel-loader']
      }
    ]
  }
)

// Transpile Enketo files.
// webpackConfig.loaders.append('enketo', {
//   test: /node_modules\/(enketo-core|openrosa-xpath-evaluator)\//,
//   loader: 'babel-loader',
// });

module.exports = webpackConfig
