# Easel Dashboard

Easel dashboard is the easiest dashboard to set up, and the easiest dashboard to
customize. With a one line install thanks to Ruby gems (see
[Installation](## Installation)), and pre-built YAML files to edit, you can be up
and running in moments.

Easel lets you choose what you see. From which commands you can run from
your dashboard, to which metrics you can see, everything can be customized
by editing a YAML file.

At no point are you at risk of foreign code execution, because Easel only runs
commands from the YAML file that is hosted on your server. The web client just
passes a command ID over the web socket, so your server is safe - even without
encryption and authentication.

## Installation

Easel dashboard is distributed as a Ruby gem, so you can install it with:

    gem install easel-dashboard

And then you can run it with:

    easel path/to/custom.yml

The most common issue with this style of installation is that `gem` does not always
expose the gems that you install to your PATH. Usually gem installs the executables
in `~/.gem/bin/` so if you're having any errors, add that to your PATH.

## Notes About the Current State

Easel is currently v0.4! At this point, it works! While the UI/UX is not polished,
and there's lots of features that I want to add before I think of Easel as a fully
functioning prototype, you can easily install and run it on any server you want!

## A Roadmap?

Easel is still in its infancy, so there's much more to come! Below are a list of
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
  - *v0.4: Easy Install -- RELEASED*
      - Let Easel be installed via one command. Possibly as a ruby gem, possibly
        with some other package manager, possibly with an install script.
  - *v0.5: A Real Dashboard*
      - Add in a default 'dashboard' page that shows common stats about the server
        such as CPU usage, network usage, memory usage, uptime, and maybe
        some maximums (and minimums) of those.
  - *v0.6: A 4, no 6, no 12 billion dollar pipeline!*
      - Implement a proper CI/CD pipeline.
      - Implement building binaries as part of the push to main (look at Ruby
        Packer). Have these be released as pre-releases.
  - *v0.7: Refactor to speed up pushing features.*
      - Refactor the client side JS (and likely the html.erb) to set up adding
        new graph types easily. See notes in app.js.erb for some preliminary ideas.
      - Refactor the server side code to have a clearer distribution of code.
  - *v0.8: Documentation for Users*
      - Add documentation on how to install Easel, and how to use it. This includes
        examples of YAML files, and explanations of the different YAML fields that are
        accepted.
  - *v0.9: YAML Validation (because silent errors suck)*
      - Add YAML validation (check that all fields are valid, error on invalid fields).
      - Ensure YAML Errors include line number from the YAML file.
  - *v0.10: Encryption Prescription*
      - Add in encryption to all communication.
  - *v0.11: Authentication Computation*
      - Add the ability to sign-in to the dashboard.
  - *v0.12: UI Rework*
      - Create a UI that can be used on Mobile.
      - Make the UI look half decent.
      - Create a logo for Easel (have it be the default logo on the dashboard)
  - *v0.13: Download logs*
      - A button to download the output of a given command.
  - *v1.0: Hello World!*
      - Easel goes out into the world! The expectation is that all the
        functionality is completed in the v0.X releases - v1.0 is focused on
        handling technical debt. This almost certainly involves a refactor, and
        will take on cleaning up the TODOs in the code base (which mostly involve
        gracefully handling edge cases).
      - The refactor will involve the following (unless a refactor of these
        systems happens before v1.0):
        - websocket.rb should not be the controller for server-run code. Core
          logic should be centralized and the websocket wrapper should be just
          that - a wrapper around the websocket.
        - Similarly, the HTTP functionality should be moved out of the server.
          A thread in the server should control the process - the details should
          be handled elsewhere.
        - The Javascript should probably be broken out of the app.hmtl.erb file,
          into it's own file.

## Other Possible Features

Other features that I'm considering, but am not sure that they would improve the
product, include the following:

  - A 'production' system, where files are built once and then served repeatedly.
      - Not sure this is worth adding. The current system is better for development
        and I don't think a production version would be a noticeable improvement,
        except in the case of YAML files with 1000s of commands (but I think
        that's unlikely).
  - When an Error occurs, display an icon in the title bar. When clicked, it
    displays the error and asks the user if they want to forward the error to me.
      - Not sure if this is via email or a web API. Probably a web API.
