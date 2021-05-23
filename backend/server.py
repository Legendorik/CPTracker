from datetime import timedelta
import uvicorn
from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from config import *
from database import schemas, models, crud
from database.crud import *
from database.database import engine
from database.crud import get_db
from sqlalchemy.orm import Session
from typing import Optional
from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")
models.Base.metadata.create_all(bind=engine)
app = FastAPI()


@app.post("/token", response_model=schemas.Token)
async def token(form_data=Depends(OAuth2PasswordRequestForm), db=Depends(get_db)):
    username = form_data.username
    password = form_data.password
    user: models.User = crud.authenticate_user(username, password, db)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires: timedelta = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token: str = crud.create_access_token(
        data={"user_id": user.id}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}


@app.post("/get_dashboard")
async def sign_in(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    slave = Slave(token, db)
    subjects = slave.action(Action.GET, Entity.SUBJECT)
    control_points = slave.action(Action.GET, Entity.CONTROL_POINT)
    cells = slave.action(Action.GET, Entity.CELL)
    return {
        "user_id": slave.user.id,
        "username": slave.user.username,
        "columns": control_points,
        "rows": subjects,
        "cells": cells
    }


@app.post("/subject")
async def create_subject(subject: schemas.Subject, token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    slave = Slave(token, db)
    try:
        slave.action(Action.CREATE, Entity.SUBJECT, subject=subject)
    except ValueError as e:
        return {"error": True, "info": str(e)}
    else:
        return await sign_in(token, db)


@app.put("/subject")
async def change_subject(old_subject: schemas.Subject, new_subject: schemas.Subject,
                         token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    slave = Slave(token, db)
    try:
        slave.action(Action.CHANGE, Entity.SUBJECT, old_subject=old_subject, new_subject=new_subject)
    except ValueError as e:
        return {"error": True, "error_type": str(e)}
    else:
        return await sign_in(token, db)


@app.delete("/subject")
async def delete_subject():
    pass


@app.post("/control_point")
async def create_control_point(control_point: schemas.TableHeader, token: str = Depends(oauth2_scheme),
                               db: Session = Depends(get_db)):
    slave = Slave(token, db)
    try:
        slave.action(Action.CREATE, Entity.CONTROL_POINT, control_point=control_point)
    except ValueError as e:
        return {"error": True, "error_type": str(e)}
    return await sign_in(token, db)


if __name__ == "__main__":
    uvicorn.run(app, host="localhost", port=8000)
