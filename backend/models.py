from sqlalchemy import Column, Integer, String, ForeignKey, Boolean
from sqlalchemy.orm import relationship, declarative_base
from sqlalchemy import create_engine

DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
Base = declarative_base()

class Exercise(Base):
    __tablename__ = "exercises"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)

class WorkoutTemplate(Base):
    __tablename__ = "workout_templates"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(String, nullable=True)
    exercises = relationship("TemplateExercise", back_populates="template")

class TemplateExercise(Base):
    __tablename__ = "template_exercises"
    id = Column(Integer, primary_key=True, index=True)
    template_id = Column(Integer, ForeignKey("workout_templates.id"))
    exercise_id = Column(Integer, ForeignKey("exercises.id"))
    order_index = Column(Integer)
    target_sets = Column(Integer)
    target_reps = Column(Integer)
    
    template = relationship("WorkoutTemplate", back_populates="exercises")
    exercise = relationship("Exercise")

class WorkoutSession(Base):
    __tablename__ = "workout_sessions"
    id = Column(Integer, primary_key=True, index=True)
    template_id = Column(Integer, ForeignKey("workout_templates.id"), nullable=True)
    date = Column(String) # Store as ISO string
    
    sets = relationship("SessionSet", back_populates="session")

class SessionSet(Base):
    __tablename__ = "session_sets"
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("workout_sessions.id"))
    exercise_id = Column(Integer, ForeignKey("exercises.id"))
    weight = Column(Integer)
    reps = Column(Integer)
    is_completed = Column(Boolean, default=False)
    
    session = relationship("WorkoutSession", back_populates="sets")
    exercise = relationship("Exercise")
