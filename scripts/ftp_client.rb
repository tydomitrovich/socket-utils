require 'socket'


#To run this script, set environment variables for user and password for the ftp
#Note that some of the output may be out of order because of the threading

#To end the program enter the command 'exit'
class FTP_Client
  @@host = '54.201.101.209'

  def initialize
    @ftp_user = ENV['ftp_user'] or fail 'No ftp username provided'
    @ftp_pass = ENV['ftp_pass'] or fail 'No ftp password provided'
    @write_mode = false
    @write_path = ''
  end

  def start
    open_command_connection(@@host, 21)
    begin
      open_data_connection(@host, 20)
    rescue Errno::ECONNREFUSED
      puts 'WARNING: Data connection refused on default data port (20)'
    end

    authenticate
  end

  def execute_command(command)
    @write_mode = false #Reset in case we wrote last command
    case command
      when 'PASV'
        @cmd_socket.puts command
        puts 'Please enter the data connection port number: '
        @data_port = gets.chomp.to_i
        @data_socket.close if nil != @data_socket
        open_data_connection(@@host, @data_port)
      when -> (cmd) {cmd.include? 'RETR'}
        puts 'Please enter a file to save remote contents in: '
        @write_path = gets.chomp
        @write_mode = true
        @cmd_socket.puts command
      when -> (cmd){cmd.include? 'STOR'}
        puts 'Please enter the path to a file to upload:'
        file = gets.chomp
        content = File.open(file, 'rb').read
        @cmd_socket.puts command
        @data_socket.puts content
      else
        @cmd_socket.puts command
    end
  end

  def open_command_connection(host, port)
    @cmd_socket = TCPSocket.open(host, port)
    @cmd_socket_response = Thread.new do
      loop{
        line = @cmd_socket.gets.chomp
        puts line
      }
    end
  end

  def open_data_connection(host, port)
    @data_socket = TCPSocket.open(host, port)
    @data_socket_response = Thread.new do
      loop{
        line = @data_socket.gets.chop
        if(@write_mode)
          File.write(@write_path, line, mode: 'a')
        else
          puts line
        end
      }
    end
  end

  def close_connections
    puts 'Closing socket connections...'
    @cmd_socket.close if nil != @cmd_socket
    @data_socket.close if nil != @data_socket
  end

  def authenticate
    puts "Authenticating User: #{@ftp_user}"
    @cmd_socket.puts "USER #{@ftp_user}"
    @cmd_socket.puts "PASS #{@ftp_pass}"
  end
end

ftp = FTP_Client.new
ftp.start

loop{
  puts 'Please enter an FTP Command: '
  line = gets.chomp
  if(line == 'exit')
    break
  else
    ftp.execute_command line
  end
}

ftp.close_connections