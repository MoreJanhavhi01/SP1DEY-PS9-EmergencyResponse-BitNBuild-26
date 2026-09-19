import asyncio
import websockets


async def test():
    async with websockets.connect("ws://127.0.0.1:8000/ws/incidents") as websocket:
        print("WebSocket connected successfully!")


asyncio.run(test())