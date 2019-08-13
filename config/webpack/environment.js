const { environment } = require('@rails/webpacker');

// Ignore JS test files.
environment.loaders.append('ignore', {
  test: /\.test\.js$/,
  loader: 'ignore-loader',
});

environment.loaders.delete('nodeModules');

module.exports = environment;
