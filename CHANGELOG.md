### Changelog ###

This file contains highlights of what changes on each version of the Dart Test
Runner package.

#### Version 0.2.8 ####

- Added windows support.

#### Version 0.2.7 ####

- Small fix so that browser tests in sub-directories work.

#### Version 0.2.6 ####

- Small fix to the browser test detection.

#### Version 0.2.5 ####

- If a test suite does not complete in 240 seconds it is aborted.

#### Version 0.2.4 ####

- If no browser tests are detected `content_shell` won't be needed.
- Added a `--skip-browser-tests` that will skip all browser tests and won't
  require `content_shell`.

#### Version 0.2.3 ####

- Tweaked command line output. Now show failed test suite details by default.

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
