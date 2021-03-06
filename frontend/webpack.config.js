/* global __dirname */

var path = require('path');

var webpack = require('webpack');

var dir_js = path.resolve(__dirname, 'js');
var dir_build = path.resolve(__dirname, '../public/');

module.exports = {
  entry: ["babel-polyfill", path.resolve(dir_js, 'main.js')],
  output: {
    path: dir_build,
    filename: 'bundle.js'
  },
  module: {
    loaders: [
      {
        loader: 'babel-loader',
        test: dir_js,
      },
      { test: /jquery/, loader: 'expose?$!expose?jQuery' }
    ]
  },
  plugins: [
    // Avoid publishing files when compilation fails
    new webpack.NoErrorsPlugin()
  ],
  stats: {
    // Nice colored output
    colors: true
  },
  // Create Sourcemaps for the bundle
  devtool: 'source-map',
};
