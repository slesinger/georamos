from flask import Flask, request, Response
from ncurses.application import Application

print(f"Starting C64Cloud server... {__name__}")
flaskApp = Flask(__name__)


app = Application()

@flaskApp.route("/")
def home():
    return "GEORAMOS"


@flaskApp.route("/K/<path:inputhex>")
def key(inputhex):
    scancodes = bytes.fromhex(inputhex)
    print(f"Scancodes  received from C64: {inputhex}") # {bytes(scancodes, 'iso8859_2')}")
    screen.dispatchScanCodes(scancodes)
    return screen.getNewScreenCodes()


'''
Poll for potential screen or terminal output data
'''
@flaskApp.route("/poll") #, methods=['GET'])
def screenPoll():
    args = request.args
    # scancodes = bytes.fromhex(args['q'])
    # app.update(args['q'])

    app.draw()
    app.screen.print_full_ascii
    # bResponse = app.screen.diff_petscii() + bytes([0x08, 0x00])
    bResponse = []
    bResponse.append(int(0x4D).to_bytes(1,'big'))
    bResponse.append(int(0x48).to_bytes(1,'big'))
    bResponse.append(int(0x4D).to_bytes(1,'big'))
    bResponse.append(int(0x48).to_bytes(1,'big'))
    x = b"".join(bResponse)
    resp = Response(x, mimetype='application/octet-stream')
    # resp.headers['Connection'] = 'Keep-Alive'
    return resp


if __name__ == '__main__':
    flaskApp.run(host='0.0.0.0', port=6464, debug=True)
