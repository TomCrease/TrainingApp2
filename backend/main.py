from fastapi import FastAPI
from .models import Base, engine

from typing import List, Optional
from pydantic import BaseModel
from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException
from .models import Base, engine, Exercise, WorkoutTemplate, TemplateExercise, WorkoutSession, SessionSet
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)

app = FastAPI()

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Pydantic Schemas
class ExerciseBase(BaseModel):
    name: str

class ExerciseCreate(ExerciseBase):
    pass

class ExerciseSchema(ExerciseBase):
    id: int
    class Config:
        orm_mode = True

@app.get("/exercises", response_model=List[ExerciseSchema])
def get_exercises(db: Session = Depends(get_db)):
    return db.query(Exercise).all()

@app.post("/exercises", response_model=ExerciseSchema)
def create_exercise(exercise: ExerciseCreate, db: Session = Depends(get_db)):
    db_exercise = Exercise(name=exercise.name)
    db.add(db_exercise)
    db.commit()
    db.refresh(db_exercise)
    return db_exercise

@app.get("/")
def read_root():
    return {"status": "FastAPI is running"}
