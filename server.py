from flask import Flask, send_from_directory, request
from flask_socketio import SocketIO
import glob
import os
import pty
import re
import select
import subprocess
import time
import yaml
# Error logging only
import logging
log = logging.getLogger('werkzeug')
log.setLevel(logging.ERROR)

# Websocket server
app = Flask(__name__,static_folder="public")
sio = SocketIO(app)



################################
#        Job functions         #
################################

# Build and return an array of stuff to process
def build_list(extension):
  # Sanitize exenstion
  extension_regex = re.sub(r'([A-Za-z])', lambda m: '[' + m.group(1).upper() + m.group(1).lower() + ']', extension)
  # Build full glob
  all_files = glob.glob('/in/**/*' + extension_regex, recursive=True)
  # Check if anything in this array has a processed log or is not a file and pull it out
  for file in all_files:
    if not os.path.isfile(file) or os.path.isfile(file + '.ffmpeg_log'):
      all_files.remove(file)  
  return all_files

# Background job thread loop for file processing
def processor():
  while True:
    files = build_list('.mkv')
    sio.emit('testout', files)
    time.sleep(5)
sio.start_background_task(processor)

################################
#         Web Server           #
################################

# Default index root
static_file_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'public')
@app.route("/")
def index():
  return send_from_directory(static_file_dir, 'index.html')

# Send the current config to the user to render
@sio.on('getconfig')
def config():
  with open("./config.yml", 'r') as stream:
    try:
      config = yaml.safe_load(stream)
      sio.emit('sendconfig', config, room=request.sid)
    except yaml.YAMLError as e:
      print(e)

# Send the current command examples from github to the user to render
@sio.on('getcommands')
def commands():
  with open("./commands.yml", 'r') as stream:
    try:
      commands = yaml.safe_load(stream)
      sio.emit('sendcommands', commands, room=request.sid)
    except yaml.YAMLError as e:
      print(e)

# Main page for rendering processing history and current
@sio.on('getmain')
def commands():
  data = 'test'
  sio.emit('sendmain', data, room=request.sid)
      
# Save user set config
@sio.on('saveconfig')
def commands(data):
  with open("/config/config.yml", 'w') as configfile:
    try:
      yaml.dump(data, configfile)
    except yaml.YAMLError as e:
      print(e)


################################
#         User Terminal        #
################################

# Globals
app.config['term'] = None
app.config['bash'] = None

# Send terminal data from forked process
def send_term():
  while True:
    # Sane delay on data sends
    sio.sleep(0.01)
    if app.config['term']:
      timeout_sec = 0
      (data_ready, _, _) = select.select([app.config['term']], [], [], timeout_sec)
      if data_ready:
        output = os.read(app.config['term'], 1024 * 20).decode()
        sio.emit('sendterm', output)

# Write user input to terminal
@sio.on('termdata')
def termdata(data):
  if app.config['term']:
    os.write(app.config['term'], data.encode())

# The user requested a terminal
@sio.on('giveterm')
def giveterm():
  if app.config['bash']:
    return
  (bash, term) = pty.fork()
  if bash == 0:
    subprocess.run('/bin/bash')
  else:
    app.config['term'] = term
    app.config['bash'] = bash
    sio.start_background_task(target=send_term)

################################
#           App Run            #
################################

if __name__ == '__main__':
  sio.run(app, port=8787, host='0.0.0.0')