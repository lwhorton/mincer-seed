Mincer-Seed
===========

## Why Mincer?

Maintaining a giant block of `<script>` is a huge pain.
```html
<script src="path/to/a-requires-jquery"></script>
<script src="path/to/b-requires-a"></script>
<script src="path/to/c-requires-b"></script>
```

Introducing the `#= require` tag. At the top of each application file, simply include a `#= require`
tag for each library / script required by that particular file (with relative path names).

```coffeescript
#= require ../../vendor/path/to/jquery
#= require ../../vendor/path/to/angular
#= require ../../component/path/to/controller
```

During the next `grunt`, mincer will inspect your application's coffee files, determine the appropriate dependency load
order, and inject a block of pre-generated `<script>` tags inside the application's html.

Before grunt:
```html
<!DOCTYPE html>
<html>
<head>
    <title></title>
</head>
<body>

<!-- #= require: example-app -->
</body>
</html>
```

After grunt:
```html
<!DOCTYPE html>
<html>
<head>
    <title></title>
</head>
<body>


<script src="static/vendor/path/to/jquery"></script>
<script src="static/vendor/path/to/angular"></script>
<script src="static/component/path/to/controller"></script>
</body>
</html>
```

But wait, there's more!

The grunt build process also moves around assets and compiles coffeescript on the fly, packaging
everything a server needs to serve your app from a single `/static` directory. Only vendor files referenced
by `#= require` are included inside `/static`, and not any extra files or cruft such as `.json`, `.bower`, or `/src/*`.

Before grunt:
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
    <component-name>.html
    ...
-vendor
    -jquery
        -dist
            jquery.min.js
        -src
            jquery.selector.js
            jquery.finder.js
            jquery.loader.js
        .bowerrc
        .npm
    -lodash
        lodash.min.js
        .bowerrc
        tracker.json
```

After grunt:
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
        <component-name>.html
        ...
-static
    -base
        base.css
    -<component-name>-app
        <component-name>.js
        <component-name>.css
        <component-name>.html
        ...
-vendor
    -jquery
        -dist
            jquery.min.js
    -lodash
        lodash.min.js
```


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
inside the base less file located in `static-src/base/`.

Inside of each `<component-name>-app/` should exist a `<component-name>.html` file that contains a comment formatted as such:
```html
<!-- #= require: <component-name> -->
```

When the grunt process runs, it will find the HTML for each component and replace the tag with a pre-generated `<script>`
tag block. Now each component of your application includes only those files absolutely necessary to function.

File directory roots for `STATIC`, `STATIC_SOURCE`, `ASSETS_ROOT`, and `VENDOR_ROOT`, are configurable via the gruntfile.
