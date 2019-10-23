let env = process.env.NODE_ENV
if (env != 'production' && env != 'development') {
  env = 'development'
}

console.log(`Environment: ${env}`)

module.exports = require(`./webpack.${env}.js`)