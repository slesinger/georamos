# flask --app c64cloud run

from flask import Flask
from screen import Screen

print("Starting C64Cloud server...")
app = Flask(__name__)


'''
This is general key input from C64
It will also return immediate output data
'''
@app.route("/K/<path:inputhex>")
def key(inputhex):
    scancodes = bytes.fromhex(inputhex)
    print(f"Scancodes  received from C64: {inputhex}") # {bytes(scancodes, 'iso8859_2')}")
    screen.dispatchScanCodes(scancodes)
    return screen.getNewScreenCodes()


'''
Poll for potential screen or terminal output data
'''
@app.route("/S/")
def screenPoll():
    return screen.getNewScreenCodes()


'''
Upload hex data to be saved on disk, stored in memory,...
Filename is captured from screen widgets beforehand.
'''
@app.route("/U/<path:inputhex>")
def upload(inputhex):
    # print(f"Save received from C64: {bytes(data, 'iso8859_2')}")
    input_bytes = bytes.fromhex(inputhex)
    null_index = input_bytes.index(b'\x00')
    filename = input_bytes[:null_index].decode("ascii") 
    data = input_bytes[null_index+1:]
    with open(filename, "wb") as binary_file:
        binary_file.write(data)
        print(f"Uploaded and saved {len(data)} to {filename}")


if __name__ == '__main__':
    screen = Screen()
    app.run(host='0.0.0.0', port=6464, debug=True)

    