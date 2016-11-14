# Ladon - A Software Modeling and Automation Framework

## Description

Ladon is a Ruby framework for codifying software architecture models and scripting automation through those models.

See the wiki (TODO) for further reading on the philosophy behind the Ladon project.

## Table of Contents

1. [Project Structure](#project-structure)
2. [Installation](#installation)
3. [Usage](#usage)
  - [Modeler](#modeler) 
  - [Automator](#automator)
  - [ladon-run](#ladon-run)
4. [Contributing](#contributing)
5. [Credits](#credits)
6. [License](#license)

##  Project Structure
  
   - `README.md`: The file you are currently reading, you rascal. You knew that.
   - `LICENSE.txt`: Framework licensing details. 
   - `CHANGELOG`: Per-version framework revision log.
   - `CONTRIBUTING.md`: Specifies the requirements for contributing to the Ladon framework.
   - `lib/`: Contains the Ladon framework source code.
   - `spec/`: RSpec BDD-style test implementations for the Ladon framework.
   - `bin/`: Holds executables that are installed onto your path when installing the Ladon framework gem.

## Installation

TODO: update when Ladon is available as a public Ruby gem. Once Ladon is open sourced, installation will be simple: `gem install ladon` command.

Until then, you will have to clone this repo and build/install the gem manually. This is simple to do:

1. Install Ruby 2.1+
2. Clone this repository and `cd` into your checkout directory
4. **Build** the Ladon gem: `gem build ladon.gemspec`
5. **Install** the built Ladon gem: `gem install ladon-1.0.0.gem`

To confirm you've successfully installed Ladon:

1. start a Ruby interpreter: `irb`
2. In your `irb` session, run: `require 'ladon'`
3. You should see `irb` return `true` for that require commands, which means the require was successful
4. Type `Ladon::Version::STRING` and confirm that a valid-looking semantic version number is returned and printed to your terminal.

If step 4 works, you're ready to go!

## Usage

Ladon 1.0 is subdivided into two components:

- Modeler: `lib/modeler.rb` and `lib/modeler/*`
- Automator: `lib/automator.rb` and `lib/automator/*`

### Modeler

Contains the framework for creating a graph-based representation of your software. 
Nodes are called "States" and edges are called "Transitions"; in other words, we're using finite state machine terminology.

This is extremely similar to the Beta. Some terminology has changed, and Transitions are now classes/objects, rather than specified through a function call.

The `Ladon::Core::PageObjectBase` class from the Beta should be represented as a subclass of Ladon 1.0's `State` class.

### Automator

Contains the framework for scripting software automation.
Ladon actually exposes two types of Automations: `Automation` and `ModelAutomation`.

While Ladon takes the philosophical stance that *all* automation should work through a model, it doesn't force you to do so.
The `Automation` class is the parent of `ModelAutomation`; the only difference is, `ModelAutomation`s are expected to use a model.

Use `ModelAutomation` unless you have a really good reason not to do so.

### ladon-run

You'll notice a single file in the `bin/` directory: `ladon-run`.

Let's say you have a `Modeler` model, and a `ModelAutomation` that uses that model to do something.
This `ladon-run` utility is how you run your `ModelAutomation`. 

When you `gem install` Ladon, this becomes an executable on your PATH that you can leverage directly: `ladon-run -h`

Fun fact: `ladon-run` is implemented as a Ladon `Automation` itself, and can serve as example code!

*Note:* consider installing the following gems, which will make your interactive mode experience more useful:

- [pry-byebug](https://github.com/deivid-rodriguez/pry-byebug)
- [pry-stack_explorer](https://github.com/pry/pry-stack_explorer)

Installing these gems will increase the power and control you have to observe and debug your automation executions.

## Contributing

Contributions definitely welcome! Refer to [CONTRIBUTING.md](CONTRIBUTING.md) for rules and guidelines. 

## Credits

Ladon was architected and implemented at **athenahealth** by [Snow](https://github.com/imjonsnooow).

## License

See [LICENSE.txt](LICENSE.txt) for authoritative licensing details.   