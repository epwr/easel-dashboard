# cdash

CDash lets you generate and serve a custom dashboard from any server using a
single command. The dashboard runs commands on the server and displays the result
via the dashboard. Use a YAML file to completely configure the dashboard including
the commands that it can run; the colours, title, and logo of the page; the host
and port to bind to, encryption defaults, and more.

*CDash Version:* v0.1

## A Roadmap?

CDash is still in its infancy, so there's much more to come! Below are a list of
features that I want to release, and a sequence for which features come next.

*Note:* No part of this roadmap is a promise. This is just my current plan.

  - *v0.1: The Beta-- RELEASED*
      - Basic functions.
      - Parsing YAML can overwrite default config values.
      - Commands are run, then stdout is sent to webpage (via websocket)
      - _Note:_ While this is usable, it's not pretty and the features are well
        below an MVP.
  - *v0.2: Updating output*
      - Make the server stream the output to the client as it's produced (allow
        for a long running program like `top`).
      - Have the client-side output include STDOUT and STDERR. These are shown as
        different colours on the client.
      - Have Client accepts a "clear" command to allow the output to be completely
        refreshed.
  - *v0.3: Easy Install*
      - Let CDash be installed via one command. Possibly as a ruby gem, possibly
        with some other package manager, possibly with an install script.
  - *v0.4: YAML Validation (because silent errors suck)*
      - Add YAML validation (check that all fields are valid, error on invalid fields).
      - Ensure YAML Errors include line number from the YAML file.
  - *v0.5: A pretty client-side*
      - Add client-side parsing of some websocket information. Allow for common
        commands (eg. top) to be parsed into attractive graphics.
  - *v0.6: Encryption Prescription*
      - Add in encryption to all communication.
  - *v0.7: Authentication Computation*
      - Add the ability to sign-in to the dashboard.
  - *v0.8: UI Rework*
      - Create a UI that can be used on Mobile.
      - Make the UI look half decent.
      - Create a logo for CDash (have it be the default logo on the dashboard)
  - *v1.0: Hello World!*
      - Likely includes a rename to align with a domain name that I can actually get.
      - Build a release testing pipeline
      - Implement a Major-Minor-Patch versioning system.
      - _Note:_ This is the point where I would consider CDash to be an MVP.
