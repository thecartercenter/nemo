const { generateWebpackConfig, merge } = require('shakapacker')

module.exports = merge(
  generateWebpackConfig(),
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
