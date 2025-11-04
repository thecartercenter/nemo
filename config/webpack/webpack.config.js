// See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.
const { generateWebpackConfig } = require('shakapacker')

const webpackConfig = generateWebpackConfig()

// Exclude test files from production builds
if (process.env.NODE_ENV === 'production') {
  webpackConfig.module.rules.push({
    test: /\.(test|spec)\.(js|jsx)$/,
    exclude: /node_modules/,
    use: 'ignore-loader'
  })
}

module.exports = webpackConfig
