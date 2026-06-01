import uvicorn
from dotenv import load_dotenv

# Load .env as the very first action so all subsequent os.getenv() calls see real values
load_dotenv()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine
from models import Base
from routers import auth_router, wardrobe_router, outfits_router, tryon_router

# Initialize FastAPI App
app = FastAPI(
    title="AI Outfit Planner API",
    description="Backend API powering the AI-driven wardrobe planner, virtual try-on, and outfit suggestions.",
    version="1.0.0"
)

# Configure CORS Middleware (allowing connection from Flutter simulator/physical device)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, restrict this to mobile app schemes or domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Startup DB Schema Creation
@app.on_event("startup")
def on_startup():
    """
    Executed on server startup. Initializes all database tables
    configured via SQLAlchemy declarative models.
    """
    print("Database Initialization: Creating tables if not existing...")
    Base.metadata.create_all(bind=engine)
    print("Database tables initialized successfully.")

# Health Check Endpoint
@app.get("/health", tags=["Health"])
def health_check():
    """
    System health check verifying that the API is fully operational.
    """
    return {
        "status": "healthy",
        "message": "AI Outfit Planner API is fully operational",
        "database": engine.name # Displays "sqlite" or "postgresql"
    }

# Mount API Routers
app.include_router(auth_router)
app.include_router(wardrobe_router)
app.include_router(outfits_router)
app.include_router(tryon_router)

if __name__ == "__main__":
    # Runs the uvicorn development server
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
