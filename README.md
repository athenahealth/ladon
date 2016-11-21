# Ladon - A Software Construction, Automation, and Reliability Framework

[![build status](https://gitlab.athenahealth.com/ssnow/ladon/badges/master/build.svg)](https://gitlab.athenahealth.com/ssnow/ladon/commits/master) [![coverage report](https://gitlab.athenahealth.com/ssnow/ladon/badges/master/coverage.svg)](https://gitlab.athenahealth.com/ssnow/ladon/commits/master)

## Description

Ladon is a Ruby framework for codifying software architecture models and scripting automation through those models.

**This is just a README.** 

See the [wiki](https://gitlab.athenahealth.com/ssnow/ladon/wikis/home) for complete high-level documentation.

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

## Credits

Ladon was architected and implemented at **athenahealth** by [Snow](https://github.com/imjonsnooow).

## License

See [LICENSE.txt](LICENSE.txt) for authoritative licensing details.   