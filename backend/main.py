
from fastapi import FastAPI
from websocket.websocket import router as websocket_router

app = FastAPI()
app.include_router(websocket_router)

# temporary fake data, standing in for the real database
incidents = []

@app.get("/")
def home():
    return {"message": "ResQ Command backend is running"}

@app.get("/incidents")
def get_incidents():
    return incidents

@app.post("/incidents")
def create_incident(incident: dict):
    incidents.append(incident)
    return {"message": "Incident added", "data": incident}