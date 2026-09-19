from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from .websocket_manager import manager


router = APIRouter()


@router.websocket("/ws/incidents")
async def incident_websocket(websocket: WebSocket):

    await manager.connect(websocket)

    try:
        while True:
            await websocket.receive_text()

    except WebSocketDisconnect:
        manager.disconnect(websocket)