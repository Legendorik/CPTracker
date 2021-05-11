from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List, Dict


class Subject(BaseModel):
    short_name: str
    full_name: str

    class Config:
        orm_mode = True


class DBSubject(Subject):
    id: int


class UserSubject(BaseModel):
    id: int
    user_id: int
    subject_id: int


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


class UserDashboard(BaseModel):
    user_id: int
    dashboard: dict[str, dict[str, Optional[dict]]]


class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    username: Optional[str] = None


class TableHeader(BaseModel):
    id: int
    short_name: str
    full_name: str


class Cell(BaseModel):
    status: Optional[bool]
    description: Optional[str]
    deadline: datetime


class Dashboard(BaseModel):
    columns: List[TableHeader]
    rows: List[TableHeader]
    cells: List[List[Cell]]
