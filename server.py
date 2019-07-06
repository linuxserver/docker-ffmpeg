from aiohttp import web
import socketio
import yaml
import os
import glob
import re
import time

# Websocket server
sio = socketio.AsyncServer(async_mode='aiohttp')
app = web.Application()
sio.attach(app)



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
async def processor():
  while True:
    files = build_list('.mkv')
    await sio.emit('testoutt', files)
    await sio.sleep(5)
sio.start_background_task(processor)

################################
#         Web Server           #
################################

# Default returns for static files and index root
async def index(request):
  with open('./public/index.html') as f:
    return web.Response(text=f.read(), content_type='text/html')
app.router.add_get('/', index)
app.router.add_static('/public/', path=str('./public/'))

# Send the current config to the user to render
@sio.on('getconfig')
async def config(sid):
  with open("./config.yml", 'r') as stream:
    try:
      config = yaml.safe_load(stream)
      await sio.emit('sendconfig', config, room=sid)
    except yaml.YAMLError as e:
      print(e)

# Send the current command examples from github to the user to render
@sio.on('getcommands')
async def commands(sid):
  with open("./commands.yml", 'r') as stream:
    try:
      commands = yaml.safe_load(stream)
      await sio.emit('sendcommands', commands, room=sid)
    except yaml.YAMLError as e:
      print(e)

# Main page for rendering processing history and current
@sio.on('getmain')
async def commands(sid):
  data = 'test'
  await sio.emit('sendmain', data, room=sid)
      
# Save user set config
@sio.on('saveconfig')
async def commands(sid, data):
  with open("/config/config.yml", 'w') as configfile:
    try:
      yaml.dump(data, configfile)
    except yaml.YAMLError as e:
      print(e)


################################
#         User Terminal        #
################################

# Terminal page rendering
@sio.on('getterminal')
async def commands(sid):
  data = 'test'
  await sio.emit('sendterminal', data, room=sid)


################################
#           App Run            #
################################

if __name__ == '__main__':
    web.run_app(app, port=8787)
