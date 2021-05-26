from sqlalchemy import Boolean, Column, ForeignKey, String, BigInteger, DateTime, CheckConstraint, UniqueConstraint
from sqlalchemy.orm import relationship
from .database import Base


class UserSubjectControlPoint(Base):
    __tablename__ = "UserSubjectControlPoint"
    user_subject_id = Column("user_subject_id", BigInteger, ForeignKey("UserSubject.id"), primary_key=True)
    control_point_id = Column("control_point_id", BigInteger, ForeignKey("ControlPoint.id"), primary_key=True)
    deadline = Column("deadline", DateTime)
    description = Column("description", String(100))
    complete = Column("complete", Boolean, default=None)
    column_number = Column("column_number", BigInteger, nullable=False)

    __table_args__ = (
        CheckConstraint("column_number >= 0", name="positive_column_number"),
    )


class UserSubject(Base):
    __tablename__ = "UserSubject"

    id = Column("id", BigInteger, primary_key=True)
    user_id = Column("user_id", BigInteger, ForeignKey("User.id"))
    subject_id = Column("subject_id", BigInteger, ForeignKey("Subject.id"))
    row_number = Column("row_number", BigInteger, nullable=False)
    control_points = relationship("ControlPoint", secondary="UserSubjectControlPoint", back_populates="users_subjects")

    __table_args__ = (
        CheckConstraint("row_number >= 0", name="positive_row_number"),
    )


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

    __table_args__ = (UniqueConstraint('short_name', 'full_name', name='subject_name_constraint'),)


class ControlPoint(Base):
    __tablename__ = "ControlPoint"

    id = Column("id", BigInteger, primary_key=True)
    short_name = Column("short_name", String(10), nullable=False)
    full_name = Column("full_name", String(70), nullable=False)
    users_subjects = relationship(UserSubject, secondary="UserSubjectControlPoint", back_populates="control_points")

    __table_args__ = (UniqueConstraint('short_name', 'full_name', name='control_point_name_constraint'),)
