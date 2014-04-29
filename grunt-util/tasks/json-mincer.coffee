Mincer  = require 'mincer'
fs      = require 'fs'
util    = require 'util'

module.exports = (grunt) ->

    grunt.registerMultiTask 'json_mincer', ->
        env     = new Mincer.Environment()
        env.appendPath p for p in @options().staticSourceRoot

        for fo in @files
            srcFile = fo.src
            dest = fo.dest
            allDeps = []
            start = +new Date()
            grunt.log.writeln "Analyzing #{srcFile.join(', ')} for dependencies."
            for fname in srcFile
                asset = env.findAsset fname

                deps = asset.dependencies
                for dep in deps
                    d = dep.logicalPath
                    continue if d in allDeps
                    allDeps.push d
                newDepName = fname
                    .replace('.js.coffee', '.js')
                    .replace('.coffee', '.js')
                allDeps.push newDepName
                grunt.verbose.writeln "Added #{newDepName} to dependency list for '#{dest}'."

            depCount = allDeps.length - 1
            srcsJnd = srcFile.join(', ')
            deltaSecs = (+new Date() - start) / 1000
            deltaSecs = deltaSecs.toFixed(2)
            grunt.log.writeln "Found #{depCount} dependencies for #{srcsJnd} (#{deltaSecs}s)"
            grunt.file.write dest, JSON.stringify(allDeps, null, 4)
            grunt.log.writeln "Dependency manifest saved to #{dest}."
            grunt.log.ok "#{dest} successfully minced!\n"


