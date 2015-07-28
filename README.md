# vistar-gulp-tasks

Tasks used in a buncha different projects.  Assumes it's a project using
Coffeescript, Less, React, Browserify, CJSX, Mocha; all the hits.

In your `package.json`

```
"devDependencies": {
  "vistar-gulp-tasks": "git://github.com/vistarmedia/gulp-tasks.git"
}

```

In your `gulpfile.coffee`

```
require('vistar-gulp-tasks')()
```

can optionally pass ye olde project object.

```
project =
  dest:   './build/'
  src:    './app/**/*.coffee'
  static: './static/**'
  index:  './static/index.html'
  style:  './style/index.less'
  test:   './test/**/*_spec.coffee'
  browserify:
    paths: ['./app']

require('vistar-gulp-tasks')(project)
```

The default project object is:

```
project =
  dest:   './build/'
  src:    './app/**/*.coffee'
  static: './static/**'
  index:  './static/index.html'
  style:  './style/index.less'
  test:   './test/**/*_spec.coffee'
  browserify:
    debug:      not isProduction()
    entries:    ['./app/index.coffee']
    extensions: ['.coffee']
    transform:  ['coffee-reactify']
```
