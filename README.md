# Little Canary

Little Canary is a tool for testing the accuracy of the telemetry emitted by an Endpoint Detection and Response (EDR) agent by allowing the user to trigger simulated threats like app launches, file changes, and network activity on-demand.

## Example

```sh
$ lc net udp exploit.org 4242 zero cool is in
$ lc file create hack.c
$ lc proc cat /etc/passwd
$ cat activity.log | jq
{
  "timestamp": "2024-08-13T18:33:00Z",
  "username": "rawburt",
  "proc_name": "/usr/local/lib/ruby/gems/3.3.0/bin/lc",
  "proc_command": "net udp exploit.org 4242 zero cool is in",
  "pid": 21045,
  "type": "net",
  "data_size": 15,
  "protocol": "udp",
  "destination_host": "exploit.org",
  "destination_port": "4242",
  "source_host": "192.168.2.134",
  "source_port": 59481
}
{
  "timestamp": "2024-08-13T18:33:09Z",
  "username": "rawburt",
  "proc_name": "/usr/local/lib/ruby/gems/3.3.0/bin/lc",
  "proc_command": "file create hack.c",
  "pid": 21070,
  "type": "file",
  "path": "/Users/rawburt/Documents/Code/little-canary/hack.c",
  "activity": "create"
}
{
  "timestamp": "2024-08-13T18:33:16Z",
  "username": "rawburt",
  "proc_name": "/usr/local/lib/ruby/gems/3.3.0/bin/lc",
  "proc_command": "proc cat /etc/passwd",
  "pid": 21096,
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

```json
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
  "timestamp": "2024-08-13T18:34:19Z",
  "username": "rawburt",
  "proc_name": "/usr/local/lib/ruby/gems/3.3.0/bin/lc",
  "proc_command": "net tcp google.com 80 hi",
  "pid": 21199,
  "type": "net",
  "data_size": 2,
  "protocol": "tcp",
  "destination_host": "google.com",
  "destination_port": "80",
  "source_host": "192.168.2.134",
  "source_port": 56938
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
  "timestamp": "2024-08-13T18:34:42Z",
  "username": "rawburt",
  "proc_name": "/usr/local/lib/ruby/gems/3.3.0/bin/lc",
  "proc_command": "net udp localhost 9090 testing 1 2 3",
  "pid": 21243,
  "type": "net",
  "data_size": 13,
  "protocol": "udp",
  "destination_host": "localhost",
  "destination_port": "9090",
  "source_host": "127.0.0.1",
  "source_port": 51692
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
