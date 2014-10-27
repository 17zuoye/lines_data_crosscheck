module.exports = (grunt) ->

  grunt.initConfig
    coffee:
      compile:
        files:
          'lib/lines_data_crosscheck.js'   : ['src/lines_data_crosscheck.coffee'],
          'lib/bar.js'                     : ['src/bar.coffee'],

  grunt.loadNpmTasks 'grunt-contrib-coffee'

  grunt.registerTask 'default', ['coffee']
