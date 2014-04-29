{
    StaticApp
    getStaticApps
    allFilesForApps
    registerApps
    configureHtml
    ModifiedManifest
} = require './grunt-util/helpers'

# Where do we want to dump our compiled scripts/assets?
STATIC = './static'

# Where are our source scripts located?
STATIC_SOURCE = './static-src'

# Where are our source assets located?
ASSETS_ROOT = './static'

# Where are our source third party libs located?
VENDOR_ROOT = './vendor'

module.exports = (grunt) ->
    config =
        pkg: grunt.file.readJSON 'package.json'
        sdist: '<%= pkg.name+"-"+pkg.version %>-src'
        bdist: '<%= pkg.name+"-"+pkg.version %>'
        static: STATIC

        _watch_:
            coffee:
                files: ["#{STATIC_SOURCE}/**/*.coffee"]
                tasks: ['coffee']
            less:
                files: ["#{STATIC_SOURCE}/**/*.less"]
                tasks: ['less']
            html:
                files: ["#{STATIC_SOURCE}/**/*.html"]
                tasks: ['require_injector']

        coffee:
            static_src:
                expand: true
                flatten: false
                cwd: STATIC_SOURCE
                src: ['**/*.coffee']
                filter: (src) ->
                    return (!(/spec\.coffee$/ig.test(src))) && grunt.manifest.hasChanged(src)
                dest: STATIC
                ext: '.js'

        copy:
            static_src_img:
                files: [
                    expand: true
                    src: "#{ASSETS_ROOT}/**/img/*"
                    dest: "#{STATIC}/img/"
                    flatten: true
                    filter: 'isFile'
                ]
            static_src_fonts:
                files: [
                    expand: true
                    src: "#{ASSETS_ROOT}/**/fonts/*"
                    dest: "#{STATIC}/fonts/"
                    flatten: true
                    filter: 'isFile'
                ]

        # This only copies vendor files, because compiled files are
        # managed by the coffee task.
            vendor_js:
                files: [
                    expand: true
                    flatten: false
                    src: ["#{VENDOR_ROOT}/**/*.js"]
                    # Filter the files to only move those actually
                    # #= require tagged inside our application.
                    filter: (name) ->
                        utilized = false
                        for file in allVendorFiles
                            if name.indexOf(file) > -1
                                utilized = true
                        return utilized
                    dest: STATIC
                ]

        # Less is constructed on the fly via mincer's registered apps,
        # the default compiles any site-wite base less files.
        less:
            default:
                files:
                    "static/css/base.css": "#{STATIC_SOURCE}/base/base.less"

    # Do not change json_mincer/require_injector here. We dynamically build these below, just
    # before we call grunt.initConfig. Offer staticSourceRoot an array of paths
    # to include when mincer is searching for files, and htmlSources as the paths
    # to the html files that <!-- #= require: --> those apps.
        json_mincer:
            options:
                staticSourceRoot: [STATIC_SOURCE, VENDOR_ROOT]

        require_injector:
            options:
                staticSourceRoot: STATIC

    grunt.manifest = new ModifiedManifest grunt

    # Setup the dynamic LESS, JSON dependency tree, and HTML injection for all registered Apps.
    staticApps = getStaticApps STATIC_SOURCE, STATIC
    registerApps staticApps, config, grunt
    configureHtml staticApps, config, grunt

    # Grab a list of all the utilized vendor files for registered apps.
    allVendorFiles = allFilesForApps(staticApps)

    grunt.initConfig config

    # Register the tasks.
    grunt.loadNpmTasks 'grunt-contrib-less'
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-copy'

    # Register project-specific tasks.
    grunt.loadTasks './grunt-util/tasks/'

    grunt.registerTask 'default', ['json_mincer', 'coffee', 'less', 'copy', 'require_injector']
    grunt.renameTask 'watch', '_watch_'
    grunt.registerTask 'watch', ['default', '_watch_']
