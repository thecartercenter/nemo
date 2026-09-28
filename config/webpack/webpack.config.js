const path = require('path');
const { generateWebpackConfig, merge } = require('shakapacker-webpack')

module.exports = merge(
    generateWebpackConfig(),
    {
        module: {
            rules: [
                {
                    test: /\.test\.js$/,
                    use: ['ignore-loader']
                },
                {
                    test: /node_modules\/(enketo-core|openrosa-xpath-evaluator)\//,
                    use: ['babel-loader']
                }
            ],
        },
        resolve: {
            alias: {
                'react-dom/client$': path.resolve(__dirname, '../../app/javascript/lib/reactDomClientCompat.js')
            },
            fallback: {
                buffer: require.resolve("buffer/")
            }
        }
    }
)
