fs = require 'fs'
path = require 'path'
crypto = require 'crypto'

class StaticApp
    constructor: (@appName, @appsRoot, @assetsRoot) ->
        @srcDirPath      = path.join @appsRoot, "#{@appName}-app"
        @srcCoffeePath   = path.join @srcDirPath, "#{@appName}.coffee"
        @assetsBuildPath = path.join @assetsRoot, 'build', "#{@appName}-app"
        @manifestPath    = path.join @assetsBuildPath, "#{@appName}.json"
        @srcLessPath     = path.join @srcDirPath, "#{@appName}.less"
        @destCSSPath     = path.join @assetsRoot, 'css', "#{@appName}-app.css"
        @destHtmlPath    = path.join @assetsRoot
        return

# Get a list of "application root" coffeescript files that follow the
# single-page-app naming convention.
# @param [String] root The root directory where static source files are
#   located. This is usually <project_root>/static-src
# @param [String] assetsRoot The root directory where compiled static files
#   are dumped into. This is usually <project_root>/assets
# @return [Array<StaticApp>] application objects to give you the bits and
#   peices of info that you need.
getStaticApps = (root, assetsRoot) ->
    contents = []
    apps = []
    try
        contents = fs.readdirSync root
    catch e
        console.error "#{root} doesn't exist."

    for name in contents
        continue unless /.*-app$/i.test(name)
        fullDirPath = path.join root, name
        appNameMatchObj = name.match(/^(.*)-app/i)
        continue unless appNameMatchObj? and appNameMatchObj[1]?
        apps.push new StaticApp appNameMatchObj[1], root, assetsRoot

    return apps

allFilesForApps = (apps) ->
    files = []
    for app in apps
        manifestPath = path.join process.cwd(), app.manifestPath
        try
            _tmpFiles = require manifestPath
        catch e
            console.error "Couldn't load manifest file."
            continue

        if _tmpFiles.length > 0
            files = files.concat _tmpFiles

    return files

registerApps = (staticApps, config, grunt) ->
    for app in staticApps
        grunt.log.ok "App Registered: '#{app.appName}'"
        # configure mincing
        config.json_mincer[app.appName] =
            files: [
                src: "#{app.appName}-app/#{app.appName}.coffee"
                dest: app.manifestPath
                cwd: app.appsRoot
            ]
        # configure the LESS task on the fly
        continue unless fs.existsSync app.srcLessPath
        config.less.apps ?= {files:{}}
        config.less.apps.files[app.destCSSPath] = app.srcLessPath
    return

configureHtml = (staticApps, config, grunt) ->
    for app in staticApps
        grunt.log.ok "HTML registered: '#{app.appName}'"
        # configure require_injector
        config.require_injector[app.appName] =
            files: [
                src: "#{app.appName}-app/#{app.appName}.html"
                cwd: app.appsRoot
                dest: app.assetsRoot
                manifest: app.manifestPath
                expand: true
            ]
    return

# On save, ModifiedManifest.hasChanged() is used to determine if they actually
# need to be recompiled. Uses an md5 of the contents for comparison.
class ModifiedManifest
    constructor: (@grunt) ->
        @manifest = {}

    hasChanged: (file) ->
        fullpath = path.join(__dirname, '..', file)
        checksum = @getChecksum(fullpath)

        unless fullpath of @manifest
            @manifest[fullpath] = checksum
            return true
        else
            if checksum == @manifest[fullpath]
                return false
            else
                @manifest[fullpath] = checksum
                return true

    getChecksum: (fullpath) ->
        contents = fs.readFileSync fullpath, 'utf8'
        return crypto
                .createHash('md5')
                .update(contents)
                .digest('hex')



module.exports = {
    StaticApp
    getStaticApps
    allFilesForApps
    registerApps
    configureHtml
    ModifiedManifest
}
