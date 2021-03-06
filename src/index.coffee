require 'gulp-cjsx'

_            = require 'lodash'
argv         = require('yargs').argv
browserify   = require 'browserify'
buffer       = require 'vinyl-buffer'
clean        = require 'gulp-clean'
concat       = require 'gulp-concat'
connect      = require 'connect'
connectjs    = require 'connect-livereload'
grepContents = require 'gulp-grep-contents'
gulp         = require 'gulp'
gulpif       = require 'gulp-if'
gutil        = require 'gulp-util'
less         = require 'gulp-less'
livereload   = require 'gulp-livereload'
mocha        = require 'gulp-mocha'
runSequence  = require 'run-sequence'
serve        = require 'serve-static'
source       = require 'vinyl-source-stream'
uglify       = require 'gulp-uglify'
watchify     = require 'watchify'


isProduction = ->
  environments = [process.env['NODE_ENV'], argv['node_env']]
  'production' in environments


defaultConfig =
  dest:     './build/'
  src:      './app/**/*.coffee'
  static:   './static/**'
  index:    './static/index.html'
  styleSrc: './style/**/*.less'
  styleApp: './app/**/*.less'
  style:    './style/index.less'
  test:     './test/**/*_spec.coffee'
  browserify:
    debug:      not isProduction()
    entries:    ['./app/index.coffee']
    extensions: ['.coffee']
    transform:  ['coffee-reactify']
  mocha:
    reporter: 'dot'


ugly = ->
  if isProduction()
    uglify()
  else
    gutil.noop()


testReporter = (config) ->
  config.mocha?.reporter or 'dot'


module.exports = (projectConfig={}) ->
  config = _.merge({}, defaultConfig, projectConfig)

  browserifyOpts = _.assign({}, watchify.args, config.browserify)
  browserified = browserify(browserifyOpts)

  runTests = (reporter=testReporter(projectConfig), bail=true) ->
    gulp.src(config.test, read: false)
      .pipe(mocha(reporter: reporter, bail: bail))
      .on 'error', (err) ->
        err.showStack = true
        gutil.log(err.toString())

  runTestsWithOnly = (reporter=testReporter(projectConfig), bail=true) ->
    gulp.src(config.test, read: true)
      .pipe(grepContents(/(describe|context|it)\.only/))
      .pipe(mocha(reporter: reporter, bail: bail))
      .on 'error', (err) ->
        err.showStack = true
        gutil.log(err.toString())

  exitOnFinish = (func, args...) ->
    func(args...)
      .on 'error', -> process.exit(1)
      .on 'end',   -> process.exit(0)

  ##############################################################################
  # TASKS
  ##############################################################################

  gulp.task 'default', ['build', 'watch']


  gulp.task 'build', ->
    runSequence('clean', ['src', 'static', 'style'])


  gulp.task 'serve', ->
    runSequence('clean', ['src', 'static', 'style'], '_serve')


  gulp.task 'watch:serve', ->
    runSequence('clean', ['src', 'static', 'style', 'watch'], '_serve')


  build = ({quiet}={}) ->
    browserified.bundle()
      .on('error', (err) ->
        gutil.log('Browserify Error', err)
        unless quiet then process.exit(1))
      .pipe(source(config.browserify.entries[0]))
      .pipe(buffer())
      .pipe(ugly())
      .pipe(concat('development-bundle.js'))
      .pipe(gulp.dest(config.dest))


  gulp.task 'clean', ->
    gulp.src(config.dest, read: false)
      .pipe(clean())


  gulp.task 'src', build


  gulp.task 'static', ->
    gulp.src(config.static)
      .pipe(gulp.dest(config.dest))


  gulp.task 'style', ->
    gulp.src(config.style)
      .pipe(less())
      .pipe(concat('style.css'))
      .pipe(gulp.dest(config.dest))


  gulp.task '_serve', ->
    lr  = livereload()
    app = connect()
    app
      .use(connectjs())
      .use(serve(config.dest))
    app.listen(process.env['PORT'] or 4001)
    livereload.listen()
    gulp.watch("#{config.dest}/**").on 'change', (file) ->
      lr.changed(file.path)


  gulp.task 'test', ->
    exitOnFinish runTests


  gulp.task 'test:only', ->
    exitOnFinish runTestsWithOnly


  gulp.task 'test:watch', ->
    runTests()
    gulp.watch([config.src, config.test], -> runTests())


  gulp.task 'watch', ->
    gulp.watch([config.test], -> runTests())

    watchified = watchify(browserified)
    watchified.on 'log', gutil.log
    watchified.on 'update', (changes) ->
      gutil.log "handling changes (#{changes.length})..."
      build(quiet: true)

    gulp.watch([config.styleApp, config.styleSrc], ['style'])
    gulp.watch(config.static, ['static'])


  gulp.task 'test:xunit', ->
    exitOnFinish runTests, reporter='mocha-jenkins-reporter', bail=false


  gulp.task 'test:spec', ->
    exitOnFinish runTests, reporter='spec'
