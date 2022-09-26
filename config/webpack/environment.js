const { environment } = require('@rails/webpacker');

// This file is similar to what what you'd have
// inside webpack.config.js for a Node project.
//
// See also babel.config.js
//
// See docs at https://webpack.js.org/configuration/

// Ignore JS test files.
environment.loaders.append('ignore', {
  test: /\.test\.js$/,
  loader: 'ignore-loader',
});

// Transpile Enketo files.
environment.loaders.append('enketo', {
  test: /node_modules\/(enketo-core|openrosa-xpath-evaluator)\//,
  loader: 'babel-loader',
});

environment.loaders.delete('nodeModules');

// For debugging:
// console.log('---\nWebpack config:\n', JSON.stringify(environment.toWebpackConfig(), null, 2), '\n---');

module.exports = environment;
