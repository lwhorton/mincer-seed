Mincer-Seed
===========

## Why use Mincer?

Maintaining clean, easily distributed front end assets is a huge pain without automation.
Maintaining a giant block of
```javascript
<script src="path/to/a"></script>
<script src="path/to/b"></script>
<script src="path/to/c"></script>
```
is similarly a huge pain, if not impossible, for larger applications.

Introducing the `#= require` tag. At the top of each application file, simply include a `#= require`
tag for each library / script required by that particular page of code.

```coffeescript
#= require path/to/jquery
#= require path/to/angular
#= require path/to/app/controller
```

During the next `grunt`, mincer will inspect all coffee files, determine the appropriate dependency load
order, and inject a block of `<script>` tags inside the appropriate html.

## Install

```bash
~$: npm install
~$: bower install
~$: grunt watch
```

## Internal conventions

Each directory under `static-src/` is intended to be a self contained component of your entire application.
The build process uses some naming conventions to automate the asset collection / compilation process.

To add a new component to your application, simply add a new dir under `static-src/<component-name>-app`,
 and within this dir be sure to include an "entry point" to that component as `<component-name>-app/<component-name>.coffee`.

 Any less for a component will similarly be named and placed as such: `<component-name>-app/<component-name>.less`.
 If a component needs more than one less file (most will), be sure to `@include ../another-component/anoother-component.less`
 inside the main less file.

 Inside of each `<component-name>-app/` should be one (and only one) html file that contains a comment formatted like this:
  ```html
  <!-- #= require: <component-name> -->
  ```
  When the grunt process runs, it will find the HTML for each component and replace the tag with all libs/scripts
  required by that component to function correctly.

 File directory roots for `STATIC`, `STATIC_SOURCE`, `ASSETS_ROOT`, and `VENDOR_ROOT`, are configurable via the gruntfile.


## File Structure

```
-grunt-util
    -tasks
        json-mincer.coffee
        require-injector.coffee
    helpers.coffee
-static-src
    -base
        base.less
    -<component-name>-app
        <component-name>.coffee
        <component-name>.less
        *.html
-vendor
```
