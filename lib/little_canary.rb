# frozen_string_literal: true

require "json"
require "time"
require "socket"
require "pathname"

module LittleCanary
  VERSION = "0.0.12"

  class FileNotFound < StandardError; end

  class Runner
    DEFAULT_LOG_FILE = "activity.log"

    # main actions
    PROC = "proc"
    FILE = "file"
    NET = "net"
    VERSION = "version"
    ACTIONS = [PROC, FILE, NET, VERSION]

    # file activities
    CREATE = "create"
    DELETE = "delete"
    MODIFY = "modify"

    # net protocols
    TCP = "tcp"
    UDP = "udp"

    def initialize(program_name, argv, pid, user, log_file = DEFAULT_LOG_FILE)
      @program_name = program_name
      @argv = argv
      @pid = pid
      @user = user
      @log_file = log_file || DEFAULT_LOG_FILE
    end

    def run!
      return usage("[#{ACTIONS.join("|")}] ...") if @argv.size == 0

      case @argv[0]
      when PROC
        return usage("proc [command ...]") if @argv.size < 2

        run_proc(@argv[1..-1].join(" "))
      when NET
        return usage("net [tcp|udp] [host] [port] [data ...]") if @argv.size < 5

        host, port, *data = @argv[2..-1]

        case @argv[1]
        when TCP
          run_net_tcp(host, port, data&.join(" "))
        when UDP
          run_net_udp(host, port, data&.join(" "))
        else
          return usage("net [tcp|udp] [host] [port] [data ...]")
        end
      when FILE
        return usage("file [create|modify|delete] ...") if @argv.size < 2

        case @argv[1]
        when CREATE
          return usage("file create [filename]") if @argv.size != 3

          run_file_create(@argv[2])
        when DELETE
          return usage("file delete [filename]") if @argv.size != 3

          run_file_delete(@argv[2])
        when MODIFY
          return usage("file modify [filename] [contents ...]") if @argv.size < 4

          run_file_modify(@argv[2], @argv[3..-1].join(" "))
        else
          return usage("file [create|modify|delete] ...")
        end
      when VERSION
        return LittleCanary::VERSION
      else
        return usage("[#{ACTIONS.join("|")}] ...")
      end

      nil
    end

    private def usage(msg)
      "usage: lc #{msg}"
    end

    private def run_proc(command)
      # hide stdout of spawned process
      io_read, io_write = IO.pipe
      pid = Process.spawn(command, out: io_write, err: [:child, :out])
      io_write.close
      Process.wait(pid)
      io_read.close

      log_activity(type: PROC)
    end

    private def run_net_tcp(host, port, data)
      data_size = data.bytesize
      source_host = nil
      source_port = nil

      TCPSocket.open(host, port.to_i) do |socket|
        source_host = socket.local_address.ip_address
        source_port = socket.local_address.ip_port

        socket.print(data) if data
      end

      destination = "#{host}:#{port}"
      source = "#{source_host}:#{source_port}"

      log_activity(
        type: NET,
        data_size: data_size,
        protocol: TCP,
        destination: destination,
        source: source,
      )
    end

    private def run_net_udp(host, port, data)
      data_size = data.bytesize

      socket = UDPSocket.new
      socket.connect(host, port.to_i)

      source_host = socket.local_address.ip_address
      source_port = socket.local_address.ip_port

      socket.send(data, 0) if data

      socket.close

      destination = "#{host}:#{port}"
      source = "#{source_host}:#{source_port}"

      log_activity(
        type: NET,
        data_size: data_size,
        protocol: UDP,
        destination: destination,
        source: source,
      )
    end

    private def run_file_create(filename)
      path = Pathname(filename)
      FileUtils.touch(path)

      log_activity(type: FILE, path: path.realpath, activity: CREATE)
    end

    private def run_file_delete(filename)
      path = Pathname(filename)

      raise FileNotFound unless File.exist?(path)

      realpath = path.realpath
      File.delete(path)

      log_activity(type: FILE, path: realpath, activity: DELETE)
    end

    private def run_file_modify(filename, content)
      path = Pathname(filename)

      raise FileNotFound unless File.exist?(path)

      File.write(path, content, mode: "a")

      log_activity(type: FILE, path: path.realpath, activity: MODIFY)
    end

    private def log_activity(data = {})
      data_to_write = {
        timestamp: Time.now.utc.iso8601,
        username: @user,
        proc_name: @program_name,
        proc_command: @argv.join(" "),
        pid: @pid,
      }.merge(data)

      File.write(@log_file, "#{JSON.dump(data_to_write)}\n", mode: "a")
    end
  end
end
