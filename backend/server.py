from datetime import timedelta
import uvicorn
from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from config import *
from database import schemas, models, crud
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
    user: models.User = await crud.authenticate_user(username, password, db)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires: timedelta = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token: str = await crud.create_access_token(
        data={"user_id": user.id}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}


@app.post("/get_dashboard")
async def sign_in(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    user: models.User = await crud.get_user_by_token(token, db)
    subjects = user.subjects
    rows = [(row.id, row.short_name, row.full_name) for row in subjects]

    control_points = await crud.get_control_points(db, user)
    columns = [(cp.id, cp.short_name, cp.full_name) for cp in control_points]
    user_subjects = await crud.get_user_subjects(user.id, db)
    cells = []
    for row in user_subjects:
        cell_row = []
        for column in columns:
            info = await crud.get_user_subject_control_point(db, row.id, column[0])
            cell = {
                "status": info.complete,
                "description": info.description,
                "deadline": info.deadline,
            }
            cell_row.append(cell)
        cells.append(cell_row)
    return {"user_id": user.id, "username": user.username, "columns": columns, "rows": rows, "cells": cells}


@app.post("/subject")
async def create_subject(subject: schemas.Subject, token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    new_subject = await crud.get_or_create(subject, db)
    user: models.User = await crud.get_user_by_token(token, db)
    try:
        user_subject: models.UserSubject = await crud.add_subject_to_user(new_subject, user, db)
    except ValueError as e:
        return {"error": True, "error_type": str(e)}
    await crud.add_control_points_to_user_subject(user, user_subject, db)
    return await sign_in(token, db)


@app.put("/subject")
async def change_subject(old_subject: schemas.Subject, new_subject: schemas.Subject,
                         token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    new_subject = await crud.get_or_create(new_subject, db)
    old_subject = await crud.get_or_create(old_subject, db)
    user: models.User = await crud.get_user_by_token(token, db)
    try:
        user_subject = await crud.update_old_subject_for_user(user, new_subject, old_subject, db)
    except ValueError as e:
        return {"error": True, "error_type": str(e)}
    await crud.add_control_points_to_user_subject(user, user_subject, db)
    return await sign_in(token, db)


@app.delete("/subject")
async def delete_subject():
    pass


if __name__ == "__main__":
    uvicorn.run(app, host="localhost", port=8000)
