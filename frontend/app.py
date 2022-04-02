from flask import Flask, jsonify, request
from flask import Flask
from flask_cors import CORS
import socket

app = Flask(__name__)
cors = CORS(app, resources={r"/api/*": {"origins": "*"}})
HOST = '127.0.0.1'  # The server's hostname or IP address
PORT = 65432        # The port used by the server
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect((HOST, PORT))

@app.route ('/api/getTruckInfo', methods=['GET', 'POST'])
def index():
    if (request.method == 'POST'):
        some_json = request.get_json()
        weight = some_json['weight']
        pickup = some_json['pickUpLocation']
        dropoff = some_json['dropOffLocation']
        some_json = 'config:distribute_cargo:' + weight + ':' + pickup + ':' + dropoff ## DO NOT CHANGE ! ##
        sock.sendall(bytes(some_json, encoding='utf-8')) # name : free cargo space : position
        return jsonify({'searchParameters' : some_json}), 201
    else:
        return jsonify({'print ' : "Hello World"})

if __name__ == '__main__':
    app.run(debug=True)  #running a server on localhost 

