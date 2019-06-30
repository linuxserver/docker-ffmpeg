from aiohttp import web
import socketio
import yaml
import os

sio = socketio.AsyncServer()
app = web.Application()
sio.attach(app)

async def index(request):
  with open('./public/index.html') as f:
    return web.Response(text=f.read(), content_type='text/html')

app.router.add_get('/', index)
app.router.add_static('/public/', path=str('./public/'))

# Send the current config to the user to render
@sio.on('getmain')
async def message(sid):
  with open("./config.yml", 'r') as stream:
    try:
      config = yaml.safe_load(stream)
      await sio.emit('sendmain', config, room=sid)
    except yaml.YAMLError as e:
      print(e)

# Send the current command examples from github to the user to render
@sio.on('getcommands')
async def message(sid):
  with open("./commands.yml", 'r') as stream:
    try:
      commands = yaml.safe_load(stream)
      await sio.emit('sendcommands', commands, room=sid)
    except yaml.YAMLError as e:
      print(e)

if __name__ == '__main__':
    web.run_app(app, port=8787)
