
yaml = require "lyaml"

manifest_path = ...

error "Missing manifest_path" if not manifest_path

strip = (str) -> str\match "^%s*(.-)%s*$"

read_cmd = (cmd) ->
  f = io.popen cmd, "r"
  with strip f\read"*a"
    assert f\close!

fin = io.open manifest_path, "r"
app = yaml.load fin\read "*a"
fin\close!

if app.dependencies
  if app.dependencies.alpine
    if app.dependencies.alpine.runtime
      print "[Runtime deps]: Found runtime OS dependencies. App: #{app.name or "this application"}"

      command = 'apk --no-cache add '
      for step, package in pairs app.dependencies.alpine.runtime
        command = command .. package
      f = io.popen command, "r"
      for line in f\lines!
        print "[Runtime deps]: #{line}"

      assert f\close!

if app.dependencies
  if app.dependencies.alpine
    if app.dependencies.alpine.buildtime
      print "[Buildtime deps]: Found buildtime OS dependencies. App: #{app.name or "this application"}"

      command = 'apk --no-cache add --virtual buildtime-dependencies '
      for step, package in pairs app.dependencies.alpine.buildtime
        command = command .. package
      f = io.popen command, "r"
      for line in f\lines!
        print "[Buildtime deps Install]: #{line}"

      assert f\close!

if app.dependencies
  if app.dependencies.luarocks
    print "[Luarocks deps]: Found luarocks packages dependencies. App: #{app.name or "this application"}"

    print "[Luarocks deps]: Installing luarocks buildtime dependencies (compilers)"
    command = 'apk --no-cache add --virtual luarocks-buildtime-dependencies build-base git cmake'
    f = io.popen command, "r"
    for line in f\lines!
      print "[Luarocks deps][Buildtime Install]: #{line}"

    assert f\close!

    for _, dep in pairs app.dependencies.luarocks
      print "[Luarocks deps]: Installing luarocks package #{dep}"
      command = "luarocks install #{dep}"
      f = io.popen command, "r"
      for line in f\lines!
        print "[Luarocks deps][#{dep}]: #{line}"

      assert f\close!

    print "[Luarocks deps]: Removing luarocks buildtime dependencies"
    command = "apk del luarocks-buildtime-dependencies"
    f = io.popen command, "r"
    for line in f\lines!
      print "[Luarocks deps][Buildtime Clean]: #{line}"

    assert f\close!

if app.dependencies
  if app.dependencies.alpine
    if app.dependencies.alpine.buildtime
      print "[Buildtime deps]: Removing buildtime OS dependencies"
      command = "apk del buildtime-dependencies"
      f = io.popen command, "r"
      for line in f\lines!
        print "[Buildtime deps Clean]: #{line}"

      assert f\close!

print "done!"
