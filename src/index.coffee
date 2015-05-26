require 'gulp-cjsx'
require 'xunit-file'


_          = require 'lodash'
argv       = require('yargs').argv
browserify = require 'browserify'
buffer     = require 'vinyl-buffer'
concat     = require 'gulp-concat'
connect    = require 'connect'
connectjs  = require 'connect-livereload'
gulp       = require 'gulp'
gulpif     = require 'gulp-if'
gutil      = require 'gulp-util'
less       = require 'gulp-less'
livereload = require 'gulp-livereload'
mocha      = require 'gulp-mocha'
serve      = require 'serve-static'
source     = require 'vinyl-source-stream'
uglify     = require 'gulp-uglify'
watchify   = require 'watchify'


isProduction = ->
  environments = [process.env['NODE_ENV'], argv['node_env']]
  'production' in environments


browserifyOptions =
  debug: not isProduction()
  entries: ['./app/index.coffee']
  extensions: ['.coffee']
  transform: ['coffee-reactify']


defaultConfig =
  dest:   './build/'
  src:    './app/**/*.coffee'
  static: './static/**'
  index:  './static/index.html'
  style:  './style/index.less'
  test:   './test/**/*_spec.coffee'

browserifyOptions = _.assign({}, watchify.args, browserifyOptions)
browserified = browserify(browserifyOptions)


ugly = ->
  if isProduction()
    uglify()
  else
    gutil.noop()


module.exports = (project=defaultConfig) ->

  runTests = (reporter='dot', bail=true) ->
    gulp.src(project.test, read: false)
      .pipe(mocha(reporter: reporter, bail: bail))
      .on 'error', (err) ->
        gutil.log(err.toString())

  exitOnFinish = (func, args...) ->
    func(args...)
      .on 'error', -> process.exit(1)
      .on 'end',   -> process.exit(0)

  ##############################################################################
  # TASKS
  ##############################################################################

  gulp.task 'default', ['build', 'watch']


  gulp.task 'build', ['src', 'static', 'style']


  gulp.task 'watch:serve', ['watch', 'serve']


  build = ->
    browserified.bundle()
      .on('error', gutil.log.bind(gutil, 'Browserify Error'))
      .pipe(source('./app/index.coffee'))
      .pipe(buffer())
      .pipe(ugly())
      .pipe(concat('app.js'))
      .pipe(gulp.dest(project.dest))

  gulp.task 'src', build


  gulp.task 'style', ->
    gulp.src(project.style)
      .pipe(less())
      .pipe(concat('app.css'))
      .pipe(gulp.dest(project.dest))


  gulp.task 'serve', ['build'], ->
    lr  = livereload()
    app = connect()
    app
      .use(connectjs())
      .use(serve(project.dest))
    app.listen(process.env['PORT'] or 4001)
    livereload.listen()
    gulp.watch("#{project.dest}/**").on 'change', (file) ->
      lr.changed(file.path)


  gulp.task 'test', ->
    exitOnFinish runTests


  gulp.task 'test:watch', ->
    runTests()
    gulp.watch([project.src, project.test], -> runTests())


  gulp.task 'watch', ->
    gulp.watch([project.test], -> runTests())

    watchified = watchify(browserified)
    watchified.on 'log', gutil.log
    watchified.on 'update', (changes) ->
      gutil.log "handling changes (#{changes.length})..."
      build()

    gulp.watch(project.style, ['style'])
    gulp.watch(project.static, ['static'])


  gulp.task 'test:xunit', ->
    exitOnFinish runTests, reporter='xunit-file', bail=false


  gulp.task 'test:spec', ->
    exitOnFinish runTests, reporter='spec'
