from aiohttp import web
import socketio

sio = socketio.AsyncServer()
app = web.Application()
sio.attach(app)

async def index(request):
  with open('./public/index.html') as f:
    return web.Response(text=f.read(), content_type='text/html')

app.router.add_get('/', index)
app.router.add_static('/public/', path=str('./public/'))

if __name__ == '__main__':
    web.run_app(app, port=8787)
