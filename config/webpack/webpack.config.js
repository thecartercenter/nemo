const { globalMutableWebpackConfig: webpackConfig, merge } = require('shakapacker')

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

module.exports = webpackConfig
