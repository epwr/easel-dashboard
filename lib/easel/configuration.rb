#!/bin/env ruby
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
  port: 4200,             # Port # to bind Easel to
  hostname: 'localhost',  # Hostname to accept. "" Accepts all connections.
  log_file: STDOUT,       # Where to write the logs to.
  title: 'Easel - Your Custom Dashboard', # The title of the dashboard webpage.
  header_logo: '',       # TODO: have nil mean default to Easel's, otherwise put in src=""
  header_title: '<a class="on-hover-secondary" href="https://easeldashboard.com">Easel Dashboard</a>', # TODO: the same as the logo line basically.
  colours: {                    # The RGB values for the dashboard. TODO: accept hsl in HTML format.
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
  commands: [  # A list of commands to allow the user to run via Easel.
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
  ],
  collect_data_period: 15,
  dashboards: [ # A list of dashboards to display
    {
      name: "Server Status",
      desc: "Basic server status.",
      id: "A", # TODO: dashboard and element IDs should be automatically added.
      elements: [
        {
          name: "CPU Load",
          type: "time-series",  # uses Time.now.strftime("%H:%M") as x asix.
          data: [
            {
              cmd:   "uptime",
              name:  "1min Average",
              regex: "average: (\\d+.\\d+)"
            },
            {
              cmd:   "uptime",
              name:  "5min Average",
              regex: ", (\\d+.\\d+),"
            },{
              cmd:   "uptime",
              name:  "15min Average",
              regex: ", (\\d+.\\d+)\\n"
            }
          ]
        },
        {
          name: "Memory",
          type: "time-series",  # uses Time.now.strftime("%H:%M") as x asix.
          data: [
            {
              cmd:   "free",
              name:  "Total Memory",
              regex: "Mem:\\W+(\\d+)"
            },
            {
              cmd:   "free",
              name:  "Free Memory",
              regex: "Mem:\\W+\\d+\\W+(\\d+)"
            }
          ]
        }
      ]
    }
  ]
}
