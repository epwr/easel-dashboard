#!/snap/bin/ruby
#
# Author: Eric Power
#
# Description:
#     This file contains the global variable $config. These values are only
#     defaults. If the YAML file passed to launch.rb contains the same keys,
#     then these values are overwritten.


# Global Variables
$config = {
  logging: 2,             # 0=Fatal, 1=Error, 2=Warning, 3=Info
  port: 4200,             # Default port
  hostname: 'localhost',  # Default hostname
  log_file: STDOUT,       # Default logging to STDOUT
  title: 'Easel - Your Custom Dashboard',
  colours: {
    surface:        '#222222',
    background:     '#000000',
    primary:        '#7DF9FF',
    secondary:      '#00FF00',
    on_surface:     '#ffffff',
    on_background:  '#ffffff',
    on_primary:     '#000000',
    on_secondary:   '#000000',
    shadow:         '#000000',
    stdout_colour:  '#ffffff',
    stderr_colour:  '#00FF00'
  },
  commands: [
      {
        name: 'Test 1',
        cmd:  'echo "this is the output of Test 1"',
        desc: 'Simple output test #1'
      },
      {
        name: 'Test 2',
        cmd:  'echo "this is the output of Test 2"',
        desc: 'Simple output test #2'
      }
  ]
}
