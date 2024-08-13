require_relative "../lib/little_canary"
require "minitest/autorun"
require "pathname"
require "json"
require "socket"
require "timeout"

class TestLittleCanary < Minitest::Test
  TEST_ROOT = __dir__
  TMP_DIR = Pathname(TEST_ROOT).join("tmp")
  TEST_LOG_FILE = TMP_DIR.join("activity.log")

  def setup
    Dir.mkdir(TMP_DIR)
  end

  def teardown
    tmp_files.each do |file|
      File.delete(file)
    end
    Dir.delete(TMP_DIR)
  end

  def tmp_files
    Dir.glob(TMP_DIR.join("*"))
  end

  def all_activity
    return [] if !File.exist?(TEST_LOG_FILE)
    activity_log = File.readlines(TEST_LOG_FILE)
    return [] if activity_log.size == 0
    activity_log.map do |activity|
      JSON.parse(activity, symbolize_names: true)
    end
  end

  def last_activity
    activity = all_activity
    return nil if activity.empty?
    activity[0]
  end

  def test_file_requires_filename
    usage = LittleCanary::Runner.new(
      "little-canary",
      ["file", "create"],
      1234,
      "robert",
      TEST_LOG_FILE
    ).run!

    assert last_activity.nil?
    assert !usage.nil?
    assert_equal "usage: lc file create [filename]", usage

    usage = LittleCanary::Runner.new(
      "little-canary",
      ["file", "modify"],
      1234,
      "robert",
      TEST_LOG_FILE
    ).run!

    assert last_activity.nil?
    assert !usage.nil?
    assert_equal "usage: lc file modify [filename] [contents ...]", usage

    usage = LittleCanary::Runner.new(
      "little-canary",
      ["file", "delete"],
      1234,
      "robert",
      TEST_LOG_FILE
    ).run!

    assert last_activity.nil?
    assert !usage.nil?
    assert_equal "usage: lc file delete [filename]", usage
  end

  def test_file_create
    test_file = TMP_DIR.join("test-tmp.txt").to_s

    assert !tmp_files.any? { |f| f.include?(test_file) }

    LittleCanary::Runner.new(
      "little-canary",
      ["file", "create", test_file],
      1234,
      "robert",
      TEST_LOG_FILE
    ).run!

    assert tmp_files.any? { |f| f.include?(test_file) }

    activity = last_activity

    assert !activity[:timestamp].nil?
    assert_equal "file", activity[:type]
    assert_equal "create", activity[:activity]
    assert_equal "robert", activity[:username]
    assert_equal "little-canary", activity[:proc_name]
    assert_equal "file create #{test_file}", activity[:proc_command]
    assert_equal 1234, activity[:pid]
  end

  def test_file_delete
    test_file = TMP_DIR.join("test-tmp-to-delete.txt").to_s

    FileUtils.touch(test_file)

    assert tmp_files.any? { |f| f.include?(test_file) }

    LittleCanary::Runner.new(
      "little-canary",
      ["file", "delete", test_file],
      1234,
      "robert",
      TEST_LOG_FILE
    ).run!

    assert !tmp_files.any? { |f| f.include?(test_file) }

    activity = last_activity

    assert !activity[:timestamp].nil?
    assert_equal "file", activity[:type]
    assert_equal "delete", activity[:activity]
    assert_equal "robert", activity[:username]
    assert_equal "little-canary", activity[:proc_name]
    assert_equal "file delete #{test_file}", activity[:proc_command]
    assert_equal 1234, activity[:pid]
  end

  def test_file_delete_no_file
    test_file = TMP_DIR.join("test-tmp-to-delete.txt").to_s

    begin
      LittleCanary::Runner.new(
        "little-canary",
        ["file", "delete", test_file],
        1234,
        "robert",
        TEST_LOG_FILE
      ).run!
      assert false
    rescue LittleCanary::FileNotFound
    end

    assert last_activity.nil?
  end

  def test_file_modify
    test_file = TMP_DIR.join("test-tmp-to-delete.txt").to_s

    FileUtils.touch(test_file)

    assert tmp_files.any? { |f| f.include?(test_file) }

    file_contents = File.read(test_file)

    LittleCanary::Runner.new(
      "little-canary",
      ["file", "modify", test_file, "abc"],
      1234,
      "robert",
      TEST_LOG_FILE
    ).run!

    assert tmp_files.any? { |f| f.include?(test_file) }

    new_file_contents = File.read(test_file)

    assert file_contents != new_file_contents
    assert_equal file_contents + "abc", new_file_contents

    activity = last_activity

    assert !activity[:timestamp].nil?
    assert_equal "file", activity[:type]
    assert_equal "modify", activity[:activity]
    assert_equal "robert", activity[:username]
    assert_equal "little-canary", activity[:proc_name]
    assert_equal "file modify #{test_file} abc", activity[:proc_command]
    assert_equal 1234, activity[:pid]
  end

  def test_file_modify_no_exist
    test_file = TMP_DIR.join("test-tmp-to-delete.txt").to_s

    begin
      LittleCanary::Runner.new(
        "little-canary",
        ["file", "modify", test_file, "abc"],
        1234,
        "robert",
        TEST_LOG_FILE
      ).run!
      assert false
    rescue LittleCanary::FileNotFound
    end

    assert last_activity.nil?
  end

  def test_proc
    LittleCanary::Runner.new(
      "little-canary-test",
      ["proc", "ls", "-la"],
      675,
      "rawburt",
      TEST_LOG_FILE
    ).run!

    activity = last_activity

    assert !activity[:timestamp].nil?
    assert_equal "proc", activity[:type]
    assert_equal "rawburt", activity[:username]
    assert_equal "little-canary-test", activity[:proc_name]
    assert_equal "proc ls -la", activity[:proc_command]
    assert_equal 675, activity[:pid]
  end

  def test_proc_error
    begin
      LittleCanary::Runner.new(
        "little-canary-test",
        ["proc", "adklfijadskfmk22"],
        675,
        "rawburt",
        TEST_LOG_FILE
      ).run!
      assert false
    rescue Errno::ENOENT
    end

    assert last_activity.nil?
  end

  def test_net_tcp_with_data
    tcp_server = Thread.new do
      Timeout::timeout(3) do
        server = TCPServer.new("localhost", "9988")
        connection = server.accept
        msg = ""
        begin
          while data = connection.read_nonblock(100) do
            msg += data
          end
        rescue Errno::EAGAIN
          retry
        rescue EOFError
        end
        connection.close
        server.close
        msg
      end
    end

    # wait for thread to setup
    sleep(0.1)

    LittleCanary::Runner.new(
      "lc",
      ["net", "tcp", "localhost", "9988", "hello", "there"],
      677,
      "rawburtz",
      TEST_LOG_FILE
    ).run!

    # `value` calls `join`
    assert_equal "hello there", tcp_server.value

    activity = last_activity

    assert !activity[:timestamp].nil?
    assert !activity[:source].nil?
    assert_equal "net", activity[:type]
    assert_equal "rawburtz", activity[:username]
    assert_equal "lc", activity[:proc_name]
    assert_equal "net tcp localhost 9988 hello there", activity[:proc_command]
    assert_equal "tcp", activity[:protocol]
    assert_equal "localhost:9988", activity[:destination]
    assert_equal 11, activity[:data_size]
    assert_equal 677, activity[:pid]
  end

  def test_net_tcp_no_connection
    # supporting ruby 3.1 and 3.3
    host_error_klass =
      if defined?(Socket::ResolutionError)
        Socket::ResolutionError
      else
        SocketError
      end

    # bad host
    begin
      LittleCanary::Runner.new(
        "lc",
        ["net", "tcp", "aklsjasdkljd", "1", "hello"],
        677,
        "rawburtz",
        TEST_LOG_FILE
      ).run!
      assert false
    rescue host_error_klass
    end

    # supporting ruby 3.1 and 3.3
    port_error_klass =
      if defined?(Socket::ResolutionError)
        Socket::ResolutionError
      else
        Errno::ECONNREFUSED
      end

    # bad port
    begin
      LittleCanary::Runner.new(
        "lc",
        ["net", "tcp", "localhost", "89893", "hello"],
        677,
        "rawburtz",
        TEST_LOG_FILE
      ).run!
      assert false
    rescue port_error_klass
    end

    assert last_activity.nil?
  end

  def test_net_udp_with_data
    tcp_server = Thread.new do
      Timeout::timeout(3) do
        received = nil
        Socket.udp_server_loop(9988) do |msg, _msg_src|
          received = msg
          break
        end
        received
      end
    end

    # wait for thread to setup
    sleep(0.1)

    LittleCanary::Runner.new(
      "lc",
      ["net", "udp", "localhost", "9988", "ab", "cd"],
      677,
      "rawburtz",
      TEST_LOG_FILE
    ).run!

    # `value` calls `join`
    assert_equal "ab cd", tcp_server.value

    activity = last_activity

    assert !activity[:timestamp].nil?
    assert !activity[:source].nil?
    assert_equal "net", activity[:type]
    assert_equal "rawburtz", activity[:username]
    assert_equal "lc", activity[:proc_name]
    assert_equal "net udp localhost 9988 ab cd", activity[:proc_command]
    assert_equal "udp", activity[:protocol]
    assert_equal "localhost:9988", activity[:destination]
    assert_equal 5, activity[:data_size]
    assert_equal 677, activity[:pid]
  end

  def test_multiple_calls_activity_log
    LittleCanary::Runner.new(
      "little-canary",
      ["file", "create", "test123"],
      1231,
      "robert",
      TEST_LOG_FILE
    ).run!

    LittleCanary::Runner.new(
      "little-canary",
      ["file", "modify", "test123", "asd"],
      1232,
      "robert",
      TEST_LOG_FILE
    ).run!

    LittleCanary::Runner.new(
      "little-canary",
      ["file", "delete", "test123"],
      1233,
      "robert",
      TEST_LOG_FILE
    ).run!

    LittleCanary::Runner.new(
      "little-canary",
      ["proc", "ls"],
      1233,
      "robert",
      TEST_LOG_FILE
    ).run!

    activity_log = all_activity

    assert_equal 4, activity_log.size
    assert_equal ["file", "file", "file", "proc"], activity_log.map { |log| log[:type] }
  end

  def test_version
    result = LittleCanary::Runner.new(
      "lc",
      ["version"],
      123,
      "rawburtz",
      TEST_LOG_FILE
    ).run!

    assert_equal LittleCanary::VERSION, result

    assert last_activity.nil?
  end
end
