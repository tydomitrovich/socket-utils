require 'socket'

host = '54.201.101.209'
port = 80

puts 'Please enter an HTTP command to run against the server: '
http_request = gets.chomp

#Running the request here
socket = TCPSocket.open(host, port)
socket.print("#{http_request} HTTP/1.0\r\n\r\n")
response = socket.read

puts response
socket.close