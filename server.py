from aiohttp import web
import socketio
import json

sio = socketio.AsyncServer()
app = web.Application()
sio.attach(app)

async def index(request):
  with open('./public/index.html') as f:
    return web.Response(text=f.read(), content_type='text/html')

app.router.add_get('/', index)
app.router.add_static('/public/', path=str('./public/'))

json = '[{"name":"test1","extension":".mkv","command":"ffmpeg -y -vaapi_device /dev/dri/renderD1339"},{"name":"test2","extension":".mkv","command":"ffmpeg -y -vaapi_device /dev/dri/renderD129"}]'

@sio.on('getmain')
async def message(sid):
  await sio.emit('sendmain', json, room=sid)

if __name__ == '__main__':
    web.run_app(app, port=8787)
