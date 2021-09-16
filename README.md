# cdash

*Current CDash Version:* v0.2

CDash lets you generate and serve a custom dashboard from any server using a
single command. The dashboard runs commands on the server and displays the result
via the dashboard. Use a YAML file to completely configure the dashboard including
the commands that it can run; the colours, title, and logo of the page; the host
and port to bind to, encryption defaults, and more.

CDash is unlikely to allow any foreign code execution, because it doesn't run any
code from the client. Instead, code is set up locally - in a YAML file - and all
client does is request the server run the code associated with an ID number. Then
the server streams the output of that command back to the client. This provides a
high level of security - even in v0.1 where there is no authentication or encryption.

## Notes About the Current State

I'm realeasing v0.2 because it does what it's supposed to do (according to my
roadmap)! That said, there's a couple really annoying UX experiences:

    - clicking on the name of the command does not run the command (it just
      loads the command's currently stored output).
    - There's no way of knowing which command is currently being shown.

Therefore, I'm changing the roadmap to make the next release focus on the UI/UX.
This is also because I've got a UI design in my head at the moment that I'm
excited about trying to realize - so this seems like a good time to switch into
designer mode! All the subsequent releases get bumped up a number (and I added
another release before v1.0 because it seemed to be needed).

## A Roadmap?

CDash is still in its infancy, so there's much more to come! Below are a list of
features that I want to release, and a sequence for which features come next.

*Note:* No part of this roadmap is a promise. This is just my current plan.

  - *v0.1: The Alpha -- RELEASED*
      - Basic functions.
      - Parsing YAML can overwrite default config values.
      - Commands are run, then stdout is sent to webpage (via websocket)
      - _Note:_ While this is usable, it's not pretty and the features are well
        below an MVP.
  - *v0.2: Updating output -- RELEASED*
      - Make the server stream the output to the client as it's produced (allow
        for a long running program like `top`).
      - Have the client-side output include STDOUT and STDERR. These are shown as
        different colours on the client.
      - Have Client accept a "clear" command to allow the output to be completely
        refreshed.
  - *v0.3: UI/UX improvements!*
      - Rehaul the UX around how selecting which command's output to show.
      - Let the user know which command's output is being shown.
      - Change the UI so that's it's actually acceptable.
      - Add some more configuration values around UI colours (eg. stdout colour,
        stderr colour).
  - *v0.4: Easy Install*
      - Let CDash be installed via one command. Possibly as a ruby gem, possibly
        with some other package manager, possibly with an install script.
  - *v0.5: YAML Validation (because silent errors suck)*
      - Add YAML validation (check that all fields are valid, error on invalid fields).
      - Ensure YAML Errors include line number from the YAML file.
  - *v0.6: Client-side can be graphs*
      - Add client-side parsing of some websocket information. Allow for common
        commands (eg. top) to be parsed into attractive graphics.
  - *v0.7: Encryption Prescription*
      - Add in encryption to all communication.
  - *v0.8: Authentication Computation*
      - Add the ability to sign-in to the dashboard.
  - *v0.9: UI Rework*
      - Create a UI that can be used on Mobile.
      - Make the UI look half decent.
      - Create a logo for CDash (have it be the default logo on the dashboard)
  - *v0.10: Download logs*
      - A button to download the output of a given command.
  - *v1.0: Hello World!*
      - This release is focused on handling technical debt. This almost certainly
        involves a refactor, and will take on cleaning up the TODOs in the code
        base (which mostly involve gracefully handling edge cases).
      - The refactor will involve the following (unless a refactor of these
        systems happens before v1.0):
        - The websocket should not be the controller for server-run code. Core
          logic should be centralized and the websocket wrapper should be just
          that - a wrapper around the websocket.
        - Similarly, the HTTP functionality should be moved out of the server.
          A thread in the server should control the process - the details should
          be handled elsewhere.
        - The Javascript should probably be broken out of the app.hmtl.erb file,
          into it's own file.
        -
      - Likely includes a rename to align with a domain name that I can actually get.
      - Build a release testing pipeline
      - Implement a Major-Minor-Patch versioning system.
      - _Note:_ This is the point where I would consider CDash to be an MVP.

## Other Possible Features

Other features that I'm considering, but am not sure that they would improve the
product, include the following:

  - A 'production' system, where files are built once and then served repeatedly.
      - Not sure this is worth adding. The current system is better for development
        and I don't think a production version would be a noticable improvement,
        except in the case of YAML files with 1000s of commands (but I think
        that's unlikely).
