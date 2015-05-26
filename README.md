# vistar-gulp-tasks

Tasks used in a buncha different projects.  Assumes it's a project using Less,
React, Browserify, CJSX, Mocha; all the hits.

In your `package.json`

```
devDependencies: {
  "vistar-gulp-tasks":  "1.0.0"
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

require('vistar-gulp-tasks')(project)
```
