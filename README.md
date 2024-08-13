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

The `proc` subcommand allows the user to spawn a process. All argument after the `proc` argument will be used to launch a new process.

```sh
usage: lc proc [command ...]
```

Example:

```sh
lc proc ls -la
```

Activity log;

```json
{
  "timestamp": "2024-08-13T15:37:26Z",
  "username": "rawburt",
  "proc_name": "/usr/local/lib/ruby/gems/3.3.0/bin/lc",
  "proc_command": "proc ls -la",
  "pid": 18514,
  "type": "proc"
}
```

### File

The `file` subcommand allows the user to create, modify, and delete files.

```sh
usage: lc file [create|modify|delete] ...
```

#### File Create

The `file create` subcommand will make a new file. It is an error to try to make a file when it already exists.

```sh
usage: lc file create [filename]
```

Example:

```sh
$ lc file create hello.txt
$ ls
activity.log	hello.txt
```

Activity log:

```sh
{
  "timestamp": "2024-08-13T15:38:00Z",
  "username": "rawburt",
  "proc_name": "/usr/local/lib/ruby/gems/3.3.0/bin/lc",
  "proc_command": "file create hello.txt",
  "pid": 18565,
  "type": "file",
  "path": "/Users/rawburt/Documents/Code/little-canary/hello.txt",
  "activity": "create"
}
```

#### File Modify

The `file modify` subcommand will append content to the specified file. It is an error to try to append to a file that does not exist.

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

Activity log:

```json
{
  "timestamp": "2024-08-13T15:38:22Z",
  "username": "rawburt",
  "proc_name": "/usr/local/lib/ruby/gems/3.3.0/bin/lc",
  "proc_command": "file modify hello.txt hi there friends",
  "pid": 18612,
  "type": "file",
  "path": "/Users/rawburt/Documents/Code/little-canary/hello.txt",
  "activity": "modify"
}
```

#### File Delete

The `file delete` subcommand will delete a file. It is an error to try to delete a file that does not exist.

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

Activity log:

```json
{
  "timestamp": "2024-08-13T15:38:45Z",
  "username": "rawburt",
  "proc_name": "/usr/local/lib/ruby/gems/3.3.0/bin/lc",
  "proc_command": "file delete hello.txt",
  "pid": 18656,
  "type": "file",
  "path": "/Users/rawburt/Documents/Code/little-canary/hello.txt",
  "activity": "delete"
}
```

### Net

The `net` subcommand allows the user to send data via TCP or UDP.

```sh
usage: lc net [tcp|udp] [host] [port] [data ...]
```

#### Net TCP

The `net tcp` subcommand allows the user to send data using TCP. The data can be any format acceptable by your shell. It is an error to try to send data to a host and port that is not listening for connections.

```sh
usage: lc net tcp [host] [port] [data ...]
```

Example:

```sh
lc net tcp google.com 80 hi
```

Activity log:

```json
{
  "timestamp": "2024-08-13T15:39:10Z",
  "username": "rawburt",
  "proc_name": "/usr/local/lib/ruby/gems/3.3.0/bin/lc",
  "proc_command": "net tcp google.com 80 hi",
  "pid": 18699,
  "type": "net",
  "data_size": 2,
  "protocol": "tcp",
  "destination": "google.com:80",
  "source": "192.168.2.134:55866"
}
```

#### Net UDP

The `net tcp` subcommand allows the user to send data using UDP. The data can be any format acceptable by your shell.

```sh
usage: lc net udp [host] [port] [data ...]
```

Example:

```sh
lc net udp localhost 9090 testing 1 2 3
```

Activity log:

```json
{
  "timestamp": "2024-08-13T15:39:47Z",
  "username": "rawburt",
  "proc_name": "/usr/local/lib/ruby/gems/3.3.0/bin/lc",
  "proc_command": "net udp localhost 9090 testing 1 2 3",
  "pid": 18763,
  "type": "net",
  "data_size": 13,
  "protocol": "udp",
  "destination": "localhost:9090",
  "source": "127.0.0.1:53549"
}
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
