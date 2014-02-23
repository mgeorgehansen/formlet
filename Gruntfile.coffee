# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

module.exports = (grunt) ->
  renameJsWithDots = (dest, src) ->
    filename = src.substring src.lastIndexOf('/'), src.length
    filename = filename.substring 0, filename.lastIndexOf('.')
    "#{dest}/#{filename}.js"

  grunt.initConfig
    srcPath: 'src'
    testPath: 'test'
    distPath: 'dist'

    package: grunt.file.readJSON 'package.json'
    licenseHeader:
      """
      /* This Source Code Form is subject to the terms of the Mozilla Public
       * License, v. 2.0. If a copy of the MPL was not distributed with this
       * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
      """
    banner:
      """
      /*! <%= package.name %> v<%= package.version %> */
      <%= licenseHeader %>
      """

    coffee:
      options:
        sourceMap: true

      dist:
        expand: true
        flatten: true
        cwd: '<%= srcPath %>'
        src: ['*.coffee']
        dest: '<%= distPath %>'
        rename: renameJsWithDots

      test:
        expand: true
        flatten: true
        cwd: '<%= testPath %>/src'
        src: ['*.coffee']
        dest: '<%= testPath %>/js'
        rename: renameJsWithDots

    coffeelint:
      options: grunt.file.readJSON 'coffeelint.json'

      gruntfile:
        files:
          src: 'Gruntfile.coffee'

      lib:
        files:
          src: ['<%= srcPath %>/*.coffee']

      test:
        files:
          src: ['<%= testPath %>/src/*.coffee']

    clean:
      dist: ['<%= distPath %>/']

      test: ['<%= testPath %>/js/']

    usebanner:
      dist:
        options:
          banner: '<%= banner %>'
        files:
          src: ['dist/*.js']

    watch:
      gruntfile:
        files: ['Gruntfile.coffee']
        tasks: ['coffeelint:gruntfile']

      lib:
        files: ['<%= srcPath %>/*.coffee']
        tasks: ['coffeelint:lib']

      dist:
        files: ['<%= srcPath %>/*.coffee']
        tasks: ['dist']

      test:
        files: ['test/src/*.coffee']
        tasks: ['test']

  grunt.loadNpmTasks 'grunt-banner'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.registerTask 'dist', [
    'clean:dist'
    'coffeelint'
    'coffee:dist'
    'usebanner:dist'
    ]
  grunt.registerTask 'test', ['clean:test', 'coffee:test']
  grunt.registerTask 'default', ['dist']
