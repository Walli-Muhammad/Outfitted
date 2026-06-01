import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# Load environment variables
load_dotenv()

# Read database URL, defaulting to local sqlite for effortless local development
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./outfit_planner.db")

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
