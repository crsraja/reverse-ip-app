import socket
import flask
from ipaddress import ip_address

def get_origin_ip():
    origin_ip = socket.gethostbyname(socket.gethostname())
    ip_reverse=ip_address(origin_ip).reverse_pointer
    reverse_ip=ip_reverse.replace(r".in-addr.arpa",'')
    return '<h1> IP : {0} Reverse IP : {1} </h1>'.format(origin_ip,reverse_ip)
output_ip = get_origin_ip()
print (output_ip)
