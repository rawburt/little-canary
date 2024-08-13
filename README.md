# Little Canary

Little Canary is a testing tool for Endpoint Detection and Response (EDR) agents. It simulates real-world threats by generating various events, such as process creation, file modifications, and network activity. By comparing EDR agent telemetry to a detailed activity log, you can accurately assess your EDR solution's effectiveness.

## Example

```sh
$ lc net tcp google.com 80 hi
$ lc file create bad.txt
$ lc proc echo hi there
$ cat activity.log | jq
{
  "timestamp": "2024-08-13T03:17:32Z",
  "username": "rawburt",
  "proc_name": "/usr/local/lib/ruby/gems/3.3.0/bin/lc",
  "proc_command": "net tcp google.com 80 hi",
  "pid": 14742,
  "type": "net",
  "data_size": 2,
  "protocol": "tcp",
  "destination": "google.com:80",
  "source": "192.168.2.134:54323"
}
{
  "timestamp": "2024-08-13T03:17:47Z",
  "username": "rawburt",
  "proc_name": "/usr/local/lib/ruby/gems/3.3.0/bin/lc",
  "proc_command": "file create bad.txt",
  "pid": 14760,
  "type": "file",
  "path": "/Users/rawburt/Documents/Code/little-canary/bad.txt",
  "activity": "create"
}
{
  "timestamp": "2024-08-13T03:17:56Z",
  "username": "rawburt",
  "proc_name": "/usr/local/lib/ruby/gems/3.3.0/bin/lc",
  "proc_command": "proc echo hi there",
  "pid": 14779,
  "type": "proc"
}
```

## Requirements

* macOS or Linux
* Ruby >= 3.1

## Installing

Building and installing the gem locally:

```sh
bundle exec rake install:local
```

## Usage

Little Canary's activity log is stored in a file named `activity.log` within the current directory. Users can specify a different log location by setting the `LC_LOG_FILE` environment variable.

Basic usage:

```sh
usage: lc [proc|file|net|version]
```

### Proc

```sh
usage: lc proc [command ...]
```

The `proc` subcommand allows the user to launch a process. For example, to run `ls -la`:

```sh
lc proc ls -la
```

### File

```sh
usage: lc file [create|modify|delete] ...
```

The `file` subcommand allows the user to create, modify, and delete files.

#### File Create

```sh
usage: lc file create [filename]
```

Example:

```sh
$ lc file create hello.txt
$ ls
activity.log	hello.txt
```

#### File Modify

```sh
usage: lc file modify [filename] [contents ...]
```

Example:

```sh
$ cat hello.txt
$ lc file modify hello.txt hi there friends
$ cat hello.txt
hi there friends
```

#### File Delete

```sh
usage: lc file delete [filename]
```

Example:

```sh
$ ls
activity.log	hello.txt
$ lc file delete hello.txt
$ ls
activity.log
```

### Net

```sh
usage: lc net [tcp|udp] [host] [port] [data ...]
```

The `net` subcommand allows the user to send data via TCP or UDP.

#### Net TCP

```sh
usage: lc net tcp [host] [port] [data ...]
```

Example:

```sh
lc net tcp google.com 80 hi
```

#### Net UDP

```sh
usage: lc net udp [host] [port] [data ...]
```

Example:

```sh
lc net tcp localhost 9090 testing 1 2 3
```

## Development

Install the dependencies:

```sh
bundle install
```

Run the tests:

```sh
bundle exec rake test
```
