from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class Subject(BaseModel):
    id: int
    short_name: str
    full_name: str

    class Config:
        orm_mode = True


class UserBase(BaseModel):
    username: str


class User(UserBase):
    id: int
    subjects: Optional[list[Subject]] = None

    class Config:
        orm_mode = True


class DBUser(UserBase):
    hash_password: str


class CreateUser(UserBase):
    password: str


# class ControlPoint(BaseModel):
#     id: int
#     short_name: str
#     full_name: str
#
#     class Config:
#         orm_mode = True
#
#
# class UserSubjectControlPoint(BaseModel):
#     id: int
#     user_subject_id: int
#     control_point_id: int
#     deadline: datetime
#     complete: bool
#
#     class Config:
#         orm_mode = True
#
#

class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    username: Optional[str] = None
