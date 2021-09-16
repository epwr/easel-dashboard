# cdash

*Current CDash Version:* v0.3

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

## Installation

CDash is distributed as a Ruby gem, so you can install it with:

    gem install cdash

And then you can run it with:

    cdash path/to/custom.yml

The most common issue with this style of installation is that `gem` does not always
expose the gems that you install to your PATH. Usually gem installs the executables
in `~/.gem/bin/` so if you're having any errors, add that to your PATH.

## Notes About the Current State

CDash is now on v0.3! At this point, it works. The UX is marginally acceptable,
and the UI is at a point that is ugly, but it's clear what things are meant to do
and hopefully its clear where the UI is headed. It still needs a lot of work though.

Next step (v0.4) is figuring out a system for easy installation. Once that's done,
then CDash can actually be used on real systems (wild), so I'm adding documentation
to the roadmap. To start, documentation will be focused on how to use CDash instead
of on documenting the code base.

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
  - *v0.3: UI/UX improvements! -- RELEASED*
      - Rehaul the UX around how selecting which command's output to show.
      - Let the user know which command's output is being shown.
      - Change the UI so that's it's actually acceptable.
      - Add some more configuration values around UI colours (eg. stdout colour,
        stderr colour).
  - *v0.4: Easy Install*
      - Let CDash be installed via one command. Possibly as a ruby gem, possibly
        with some other package manager, possibly with an install script.
  - *v0.5: Documentation for Users*
      - Add documentation on how to install CDash, and how to use it. This includes
        examples of YAML files, and explanations of the different YAML fields that are
        accepted.
  - *v0.6: YAML Validation (because silent errors suck)*
      - Add YAML validation (check that all fields are valid, error on invalid fields).
      - Ensure YAML Errors include line number from the YAML file.
  - *v0.7: Client-side can be graphs*
      - Add client-side parsing of some websocket information. Allow for common
        commands (eg. top) to be parsed into attractive graphics.
  - *v0.8: Encryption Prescription*
      - Add in encryption to all communication.
  - *v0.9: Authentication Computation*
      - Add the ability to sign-in to the dashboard.
  - *v0.10: UI Rework*
      - Create a UI that can be used on Mobile.
      - Make the UI look half decent.
      - Create a logo for CDash (have it be the default logo on the dashboard)
  - *v0.11: Download logs*
      - A button to download the output of a given command.
  - *v1.0: Hello World!*
      - CDash goes out into the world! The expectation is that all the
        functionality is completed in the v0.X releases - v1.0 is focused on
        handling technical debt. This almost certainly involves a refactor, and
        will take on cleaning up the TODOs in the code base (which mostly involve
        gracefully handling edge cases).
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
      - Likely includes a rename to align with a domain name that I can actually get.
      - Build a release testing pipeline
      - Add documentation on the actual codebase to help future development.
      - Implement a Major-Minor-Patch versioning system.

## Other Possible Features

Other features that I'm considering, but am not sure that they would improve the
product, include the following:

  - A 'production' system, where files are built once and then served repeatedly.
      - Not sure this is worth adding. The current system is better for development
        and I don't think a production version would be a noticable improvement,
        except in the case of YAML files with 1000s of commands (but I think
        that's unlikely).
