from typing import Optional
from datetime import datetime
from pydantic import BaseModel


class UserBase(BaseModel):
    username: str


class DBUser(UserBase):
    hash_password: str


class CreateUser(UserBase):
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str


class TableHeader(BaseModel):
    short_name: str
    full_name: str


class Cell(BaseModel):
    deadline: Optional[datetime]
    description: Optional[str]
    complete: Optional[bool]
