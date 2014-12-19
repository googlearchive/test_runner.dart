### Changelog ###

This file contains highlights of what changes on each version of the Dart Test
Runner package.

#### Version 0.2.2 ####

- Exit code `3` if no test files were found.

#### Version 0.2.1 ####

- Fixes to have the test runner work with `pub global activate` and `pub global
  run`.
- Moved a lot of the code under `lib`.

#### Version 0.2.0 ####

- Now using Code Generation to make sure unittests are ran in a correct
  environment. Basically we set the unittest configuration.

#### Version 0.1.0 ####

- Initial version that can run both Standalone VM and Web tests with basic
  output.
