import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# Load environment variables
load_dotenv()

# Read database URL
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    # Fail loudly in production to prevent fallback to local ephemeral SQLite
    if os.getenv("ENVIRONMENT") == "production" or os.getenv("RAILWAY_STATIC_URL"):
        raise ValueError("DATABASE_URL environment variable must be set in production.")
    DATABASE_URL = "sqlite:///./outfit_planner.db"

# Handle SQLAlchemy 1.4+ compatibility for postgres schema prefix if provided by Railway
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# Setup connect arguments for sqlite compatibility
connect_args = {}
if DATABASE_URL.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

# Create engine
engine = create_engine(
    DATABASE_URL,
    connect_args=connect_args
)

# Session maker
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Declarative base class for models
Base = declarative_base()

# Database dependency injection function
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
