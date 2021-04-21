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

models.Base.metadata.create_all(bind=engine)
app = FastAPI()


@app.post("/token", response_model=schemas.Token)
async def login_for_access_token(form_data=Depends(OAuth2PasswordRequestForm), db=Depends(get_db)):
    user: schemas.DBUser = await crud.authenticate_user(form_data.username, form_data.password, db)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires: timedelta = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token: str = await crud.create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}


@app.get("/users/{user_id}")
async def read_user(user_id: int, db: Session = Depends(get_db)):
    db_user: Optional[models.User] = await crud.get_user(db, user_id=user_id)
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user


@app.get("/users/guard/me")
async def read_user_with_token(user: schemas.User = Depends(crud.get_user_by_token)):
    return user


@app.post("/users/")
async def create_user(user: schemas.CreateUser, db: Session = Depends(get_db)):
    db_user = await crud.get_user_by_username(db, user.username)
    if db_user:
        raise HTTPException(status_code=400, detail="username is already exists")
    else:
        return await crud.create_user(db, user)


if __name__ == "__main__":
    uvicorn.run(app, host="localhost", port=8000)
