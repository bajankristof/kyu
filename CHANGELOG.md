# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.2] - 2022-12-15
### Fixed
- bad MFA in `kyu_consumer:child_spec/1`

## [2.0.1] - 2022-12-15
### Fixed
- bad `kyu:declare` call in `kyu_publisher`

## [2.0.0] - 2022-12-15
### Updated
- redesigned the whole architecture of the project
- the `kyu_channel` now interacts with channels directly
- the `kyu_consumer` and `kyu_worker` modules are now more robust
    - they require less channels
    - the `kyu_wrangler` layer was completely removed, so workers now receive messages directly
    - the `kyu_worker` module supports more optional callbacks (`init/1`, `handle_call/3`, `handle_cast/2`, `terminate/2`)
    - consumer behaviour is more predictable due to a single `prefetch_count` option (`worker_count` was removed)
    - `duplex` consumers now use a single channel to receive and publish messages
    - workers can now retreive their channels using `kyu_worker:channel/0`
- publishers can now be pooled using `kyu_publisher:child_spec/2` or `kyu_publisher:start_link/2`
- publishers don't require you to set `mandatory` on a message when using the `supervised` execution mode

## [1.2.2] - 2021-05-31
### Fixed
- `handle_info` callbacks overriding the whole worker state with incorrect data

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
