const { environment } = require('@rails/webpacker');

// Ignore JS test files.
environment.loaders.append('ignore', {
  test: /\.test\.js$/,
  loader: 'ignore-loader',
});

environment.loaders.delete('nodeModules');

environment.splitChunks();

// https://github.com/rails/webpacker/issues/2268
environment.config.set('optimization.splitChunks.cacheGroups.styles', {
  name: 'styles',
  test: (module) => (module.type === 'css/mini-extract'),
});

module.exports = environment;
