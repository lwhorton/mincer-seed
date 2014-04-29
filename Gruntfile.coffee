{
    StaticApp
    getStaticApps
    allFilesForApps
    registerApps
    configureHtml
    ModifiedManifest
} = require './grunt-util/helpers'

# Where do we want to dump our compiled scripts/assets? This is the single
# directory from which we can serve our application.
STATIC = './static'

# Where is the source code located?
STATIC_SOURCE = './static-src'

# Where are the source assets (images, sounds, etc.) located?
ASSETS_ROOT = './static'

# Where is the third party source code located?
VENDOR_ROOT = './vendor'

module.exports = (grunt) ->
    config =
        pkg: grunt.file.readJSON 'package.json'
        sdist: '<%= pkg.name+"-"+pkg.version %>-src'
        bdist: '<%= pkg.name+"-"+pkg.version %>'

        # Watch coffee/less/html for changes and rebuild only those modified components.
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

        # Move any vendor files utilized by application into STATIC.
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

        # Do not change json_mincer/require_injector here. We dynamically build these options
        # before we call grunt.initConfig.

        # Provide mincer with an array of paths that point to any files where #= require tags
        # might be trying to reach. Usually this is just /static-src and /vendor.
        json_mincer:
            options:
                staticSourceRoot: [STATIC_SOURCE, VENDOR_ROOT]

        # Provide the injector with the final destination of compiled html files.
        require_injector:
            options:
                staticSourceRoot: STATIC

    grunt.manifest = new ModifiedManifest grunt

    # Setup the dynamic LESS, JSON dependency tree, and HTML injection for all registered Apps.
    staticApps = getStaticApps STATIC_SOURCE, STATIC
    registerApps staticApps, config, grunt
    configureHtml staticApps, config, grunt

    # Grab a list of all the utilized vendor files for registered apps (for use by require_injector).
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
