fs = require 'fs'
path = require 'path'
mincer = require 'mincer'

module.exports = (grunt) ->

    grunt.registerMultiTask 'require_injector', ->

        env = new mincer.Environment()
        env.appendPath p for p in @options().staticSourceRoot

        # Iterate each app, find its html, search the html for <!-- #= require: { app } -->,
        # then replace any existing require comments with a block of <script> from the manifest.
        for fo in @files

            # Filter the filepaths to warn on 'no file found'.
            fltr = (filepath) ->
                if not grunt.file.exists filepath
                    grunt.log.warn "HTML file '#{filepath}' could not be read found."
                    return false
                else
                    return true

            # Read out the contents of the html file, then search it for require tags.
            grunt.log.writeln "Searching #{fo.src.join(', ')} for <!-- #= require: #{@target} -->"
            contents = (fo.src.filter(fltr).map (filepath) ->
                return grunt.file.read filepath )[0]

            # Read in our list of dependencies, building up a <script> block.
            dependencies = grunt.file.readJSON fo.manifest
            scriptBlock = ''
            for dep in dependencies
                scriptBlock += "\n <script type=\"text/javascript\" src=\"#{@options().staticSourceRoot}/#{dep}\"></script>"

            tag = /<!--\s*#=\s*require\s*:\s*(?!-->)[\w-]*\s*-->/im
            if tag.test(contents)
                html = contents.replace(tag, scriptBlock)

                # Write the new html file.
                grunt.file.write fo.dest, html
                grunt.log.ok "#{fo.dest} generated with <script> blocks."








