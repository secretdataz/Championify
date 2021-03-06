async = require 'async'
clean = require 'gulp-clean'
fs = require 'fs-extra'
glob = require 'glob'
gulp = require 'gulp'
mkdirp = require 'mkdirp'
path = require 'path'
runSequence = require 'run-sequence'

pkg = require '../package.json'

symlink = (source, cb) ->
  glob './' + source + '/**', {nodir: true} , (err, paths) ->
    console.log paths
    async.each paths, (oldPath, acb) ->
      newPath = oldPath.replace('./' + source, './dev')
      oldPath = oldPath.replace('./' + source + '/', process.cwd()+'/' + source + '/')
      fs.symlink oldPath, newPath, (err) ->
        acb null
    , ->
      cb()

# Dirs, Copy, Delete, Mk
gulp.task 'mkdir:app', (cb) ->
  glob './app/**/' , (err, paths) ->
    async.each paths, (path, acb) ->
      path = path.replace('./app', './dev')
      mkdirp path, ->
        acb()
    , ->
      cb()


gulp.task 'copy:app', (cb) ->
  glob './app/**' , {nodir: true}, (err, files) ->
    async.each files, (file, acb) ->
      newfile = file.replace('./app', './dev')
      fs.copy file, newfile, (err) ->
        console.log err if err
        acb()
    , ->
      cb()

gulp.task 'copy:data', (cb) ->
  fs.copy './data/', './dev/data', (err) -> cb(err)


gulp.task 'symlink:app', (cb) ->
  glob './app/**', {nodir: true} , (err, paths) ->
    async.each paths, (oldPath, acb) ->
      newPath = oldPath.replace('./app', './dev')
      oldPath = oldPath.replace('./app/', process.cwd()+'/app/')
      fs.symlink oldPath, newPath, (err) ->
        acb null
    , ->
      cb()


gulp.task 'dev_folder', (cb) ->
  if process.platform == 'win32'
    runSequence('copy:app', cb)
  else
    runSequence('symlink:app', cb)

gulp.task 'delete-dev', ->
  gulp.src(['./dev', './tmp'])
    .pipe(clean(force: true))

gulp.task 'delete-releases', ->
  gulp.src(['./releases'])
    .pipe(clean(force: true))

gulp.task 'create-releases-folder', (cb) ->
  mkdirp './releases', -> cb()

gulp.task 'move:asar:update', (cb) ->
  fs.copy './tmp/app.asar', './releases/update.asar', -> cb()

gulp.task 'move:compiled-win:folder', (cb) ->
  fs.move path.join('./tmp', pkg.name), path.join('./releases', pkg.name), {clobber: true}, (err) ->
    cb(err)

gulp.task 'move:compiled-mac:folder', (cb) ->
  fs.move path.join('./tmp', pkg.name + '.app'), path.join('./releases', pkg.name + '.app'), {clobber: true}, (err) ->
    cb(err)
