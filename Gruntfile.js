module.exports = function(grunt) {
    // Project configuration.
    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        coffee: {
            'dist/build.all.js': ['Frontend.coffee','components/*.coffee']
        },
        uglify: {
            dist: {
                files: {
                    'dist/build.all.min.js': ['dist/build.all.js']
                }
            }
        }
    });
    
    
    
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-uglify');
    
    
    grunt.registerTask('default', ['coffee','uglify']);
};
