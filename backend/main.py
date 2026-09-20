""" 
#from xml.parsers.expat import model

from fastapi import FastAPI
from websocket.websocket import router as websocket_router
from ai_model import model

#print(model.encode("Warehouse fire in Surat"))
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

 """



from fastapi import FastAPI
from websocket.websocket import router as websocket_router
from ai_model import model
from ai.duplicate_detector import check_duplicate
from database import engine
from sqlalchemy import text
from database import engine
from database import SessionLocal
from sqlalchemy import text
from sklearn.metrics.pairwise import cosine_similarity
import models

app = FastAPI()
#models.Base.metadata.create_all(bind=engine)
with engine.connect() as conn:
    result = conn.execute(text("SELECT 1"))
    print("Database Connected Successfully ✅")
app.include_router(websocket_router)

incidents = []

@app.get("/")
def home():
    return {"message": "ResQ Command backend is running"}

@app.get("/encode")
def encode(text: str):
    embedding = model.encode(text).tolist()
    return {
        "text": text,
        "embedding": embedding
    }

""" @app.post("/duplicate-check")
def duplicate_check(data: dict):

    existing = [
        "Warehouse fire in Surat",
        "Flood in Vadodara",
        "Gas leak in GIDC",
        "Road accident on NH48"
    ]

    new_embedding = model.encode(data["text"])

    scores = []

    for incident in existing:
        emb = model.encode(incident)
        score = cosine_similarity(
            [new_embedding],
            [emb]
        )[0][0]

        scores.append({
            "incident": incident,
            "similarity": round(float(score), 3)
        })

    best = max(scores, key=lambda x: x["similarity"])

    return {
        "duplicate": best["similarity"] > 0.75,
        "best_match": best
    } """
""" 
@app.get("/incidents")
def get_incidents():
    return incidents """
@app.get("/incidents")
def get_incidents():
    db = SessionLocal()

    result = db.execute(text("""
        SELECT reference_code,
               title,
               severity_score,
               status,
               location_text
        FROM  resq.incidents
        ORDER BY reported_at DESC;
    """))

    incidents = []

    for row in result:
        incidents.append({
            "reference_code": row.reference_code,
            "title": row.title,
            "severity_score": row.severity_score,
            "status": row.status,
            "location": row.location_text
        })

    db.close()

    return incidents
""" @app.post("/incidents")
def create_incident(incident: dict):
    incidents.append(incident)
    return {"message": "Incident added", "data": incident} """


@app.post("/incidents")
def create_incident(incident: dict):
    db = SessionLocal()

    db.execute(
        text("""
            INSERT INTO resq.incidents
            (
                reference_code,
                title,
                description,
                location_text,
                severity_score,
                status
            )
            VALUES
            (
                :reference_code,
                :title,
                :description,
                :location_text,
                :severity_score,
                :status
            )
        """),
        incident
    )

    db.commit()
    db.close()

    return {
        "message": "Incident Added Successfully"
    }

@app.post("/detect-duplicate")
def detect_duplicate(data: dict):

    existing_reports = [
        "Warehouse fire in Surat",
        "Flood in Vadodara",
        "Gas leak in Rajkot",
        "Medical emergency in Ahmedabad"
    ]

    result = check_duplicate(
        data["description"],
        existing_reports
    )

    return result