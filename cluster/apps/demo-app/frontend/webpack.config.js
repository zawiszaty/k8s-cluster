const path = require('path');

module.exports = {
  entry: './src/otel.js',
  output: {
    filename: 'otel-bundle.js',
    path: path.resolve(__dirname, 'dist'),
    library: {
      name: 'otel',
      type: 'window',
      export: 'default'
    }
  },
  mode: 'production',
  target: 'web',
  resolve: {
    fallback: {
      // Node.js core modules not needed in browser
      "path": false,
      "fs": false,
      "os": false,
      "util": false,
      "stream": false,
      "buffer": false,
      "process": false
    }
  }
};
