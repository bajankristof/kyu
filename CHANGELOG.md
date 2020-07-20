# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2020-07-20
### Added
- option `duplex` to consumers to be able to use their channels as publishers
- kyu_uuid module to create unique identifiers for supervised messages

### Updated
- completely revamped the way the application handles channels
- all common tests for better coverage
- most of the low-level API functions
- application dependencies

## [0.1.4] - 2020-03-30
### Added
- optional `id` option to child_spec functions

## [0.1.3] - 2020-03-30
### Added
- `init/1` optional `kyu_worker` callback
- `kyu_message` module to interface messages
- `kyu_publisher` message validation

### Updated
- documentation

### Removed
- logs from `kyu_publisher`, `kyu_wangler` and `kyu_worker`

## [0.1.2] - 2020-03-29
### Updated
- `kyu.queue.unbind` command (see README.md)
- internal consumer workflow

### Removed
- `kyu_connection:channel/2`

### Fixed
- ignored header files
- blocking `kyu_connection:channel/1` call
