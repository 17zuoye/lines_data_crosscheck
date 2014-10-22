module.exports = (grunt) ->

  grunt.initConfig
    coffee:
      compile:
        files:
          'lib/lines_data_crosscheck.js': ['src/*.coffee']

  grunt.loadNpmTasks 'grunt-contrib-coffee'

  grunt.registerTask 'default', ['coffee']
