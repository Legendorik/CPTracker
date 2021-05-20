from sqlalchemy import Boolean, Column, ForeignKey, String, BigInteger, DateTime, CheckConstraint, UniqueConstraint
from sqlalchemy.orm import relationship
from .database import Base


class UserSubjectControlPoint(Base):
    __tablename__ = "UserSubjectControlPoint"
    id = Column("id", BigInteger, primary_key=True)
    user_subject_id = Column("user_subject_id", BigInteger, ForeignKey("UserSubject.id"), primary_key=True)
    control_point_id = Column("control_point_id", BigInteger, ForeignKey("ControlPoint.id"), primary_key=True)
    deadline = Column("deadline", DateTime, nullable=False)
    description = Column("description", String(100))
    complete = Column("complete", Boolean, default=None)

    __table_args__ = (
        CheckConstraint("deadline > current_date + 1", name="deadline_in_future"),
    )


class UserSubject(Base):
    __tablename__ = "UserSubject"

    id = Column("id", BigInteger, primary_key=True)
    user_id = Column("user_id", BigInteger, ForeignKey("User.id"))
    subject_id = Column("subject_id", BigInteger, ForeignKey("Subject.id"))
    control_points = relationship("ControlPoint", secondary="UserSubjectControlPoint", back_populates="users_subjects")


class User(Base):
    __tablename__ = "User"

    id = Column("id", BigInteger, primary_key=True)
    username = Column("username", String(30), unique=True, nullable=False)
    hash_password = Column("hash_password", String(100), nullable=False)
    subjects = relationship("Subject", secondary="UserSubject", back_populates="users")


class Subject(Base):
    __tablename__ = "Subject"

    id = Column("id", BigInteger, primary_key=True)
    short_name = Column("short_name", String(10), nullable=False)
    full_name = Column("full_name", String(70), nullable=False)
    users = relationship(User, secondary="UserSubject", back_populates="subjects")

    __table_args__ = (UniqueConstraint('short_name', 'full_name', name='short_full_name_constraint'),)


class ControlPoint(Base):
    __tablename__ = "ControlPoint"

    id = Column("id", BigInteger, primary_key=True)
    short_name = Column("short_name", String(10), unique=True, nullable=False)
    full_name = Column("full_name", String(70), unique=True, nullable=False)
    users_subjects = relationship(UserSubject, secondary="UserSubjectControlPoint", back_populates="control_points")
