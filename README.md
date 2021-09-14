# cdash

CDash lets you generate and serve a custom dashboard from any server using a
single command. The dashboard runs commands on the server and displays the result
via the dashboard. Use a YAML file to completely configure the dashboard including
the commands that it can run; the colours, title, and logo of the page; the host
and port to bind to, encryption defaults, and more.

## Roadmap

_Note_: This roadmap is for my mental 'what should I do next', and not a promise
of upcoming features. This may change at any point.

  - *v0.1: The MVP*
      - Build a websocket to let the dashboard show the results of running the command.
      - Finish the ERB files for the app and css.
      - Add HTML parsing to serve the app, css, and favicon.
  - *v0.2: YAML Validation (because silent errors suck)*
      - YAML validation (check that all fields are valid, error on invalid fields).
      - YAML Errors include line number from the YAML file.
  - *v0.3: A pretty client-side*
      - Client-side parsing of some websocket information. Allow for common
        commands (eg. top) to be parsed into attractive graphics.
      - Client-side differentiation between STDOUT and STDERR (colour?) messages
  - *v0.4: Encryption Prescription*
      - Add in encryption to all communication.
