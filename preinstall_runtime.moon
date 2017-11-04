
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
        command = command .. package .. ' '
      f = io.popen command, "r"
      for line in f\lines!
        print "[Runtime deps]: #{line}"

      assert f\close!

print "done!"
