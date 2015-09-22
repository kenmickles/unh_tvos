gulp = require 'gulp'
coffee = require 'gulp-coffee'
jade = require 'gulp-jade'
fs = require 'fs'
rename = require 'gulp-rename'
insert = require 'gulp-insert'
clean = require 'gulp-clean'
runSequence = require 'run-sequence'
server = require 'gulp-server-livereload'
awspublish = require 'gulp-awspublish'

SOURCE_DIR = "./app/"
BUILD_DIR = "./dist/"

sources = {
  images: ["#{SOURCE_DIR}images/**/*.*"]
  scripts: ["#{SOURCE_DIR}js/**/*.js"]
  coffee: ["#{SOURCE_DIR}js/**/*.coffee"]
  templates: ["#{SOURCE_DIR}templates/**/*.jade"]
  data: ["#{SOURCE_DIR}data/*.json"]
}

destinations = {
  images: "#{BUILD_DIR}images"
  scripts: "#{BUILD_DIR}js"
  templates: "#{BUILD_DIR}templates"
}

loadData = ->
  data = {}
  dataDir = "#{SOURCE_DIR}data/"
  files = fs.readdirSync(dataDir)
  
  for file in files
    key = file.replace(/\.json$/, '')
    data[key] = JSON.parse(fs.readFileSync("#{dataDir}#{file}", encoding: 'utf8'))

  data

gulp.task 'images', ->
  gulp.src(sources.images)
    .pipe(gulp.dest(destinations.images))

gulp.task 'coffee', ->
  gulp.src(sources.coffee)
    .pipe(coffee(bare: true).on('error', console.log))
    .pipe(gulp.dest(destinations.scripts))

gulp.task 'scripts', ->
  gulp.src(sources.scripts)
    .pipe(gulp.dest(destinations.scripts))

gulp.task 'templates', ->
  gulp.src(sources.templates)
    .pipe(jade(
      locals: loadData()
      pretty: true
    ))
    .pipe(insert.prepend('var Template = function() { return `<?xml version="1.0" encoding="UTF-8" ?>'))
    .pipe(insert.append("`\n}"))
    .pipe(rename(extname: ".xml.js"))
    .pipe(gulp.dest(destinations.templates))

gulp.task 'watch', ->
  gulp.watch(sources.images, ['images'])
  gulp.watch(sources.coffee, ['coffee'])
  gulp.watch(sources.scripts, ['scripts'])
  gulp.watch(sources.templates, ['templates'])
  gulp.watch(sources.data, ['templates'])

gulp.task 'clean', ->
  gulp.src(BUILD_DIR, read: false)
    .pipe(clean(force: true))

gulp.task 'build', ->
  runSequence('clean', ['images', 'scripts', 'coffee', 'templates'])

gulp.task 'serve', ->
  gulp.src(BUILD_DIR)
    .pipe(server(
      livereload: false
      port: 9001
      open: false
      host: '0.0.0.0'
    ))

gulp.task 'awspublish', ->
  publisher = awspublish.create(
    accessKeyId: process.env.S3_KEY
    secretAccessKey: process.env.S3_SECRET
    params: {
      Bucket: "unh-appletv"
    }
  )

  headers = {
    'Cache-Control': 'max-age=60, no-transform, public'
  }

  gulp.src("#{BUILD_DIR}**")
    .pipe(awspublish.gzip(ext: ''))
    .pipe(publisher.publish(headers))
    .pipe(publisher.sync())
    .pipe(awspublish.reporter())

gulp.task 'deploy', ->
  runSequence('build', 'awspublish')
  setTimeout ->
    runSequence('awspublish')
  , 1000

##
gulp.task 'default', ->
  runSequence('build', 'watch', 'serve')