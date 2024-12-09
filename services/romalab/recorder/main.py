# TO DO
# fix frontend and return some user endpoints
from datetime import datetime, timedelta
from typing import List, Optional

from fastapi import Depends, FastAPI, HTTPException, Request, Response, status, Form
from fastapi.security import OAuth2PasswordBearer
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from jose import JWTError, jwt
from sqlmodel import Field, Relationship, Session, SQLModel, create_engine, select
from pydantic import BaseModel

app = FastAPI(title="Recorder API", version="1.0.0")
#templates = Jinja2Templates(directory="templates")

# Настройка базы данных
import os
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Fetch database configuration from environment variables
DATABASE_USER = os.getenv("RECORDER_DB_USER", "local")
DATABASE_PASSWORD = os.getenv("RECORDER_DB_PASSWORD", "local")
DATABASE_HOST = os.getenv("RECORDER_DB_HOST", "localhost")
DATABASE_PORT = os.getenv("RECORDER_DB_PORT", "5432")
DATABASE_NAME = os.getenv("RECORDER_DB_NAME", "postgres")


# Construct the PostgreSQL database URL
DATABASE_URL = (
    f"postgresql://{DATABASE_USER}:{DATABASE_PASSWORD}"
    f"@{DATABASE_HOST}:{DATABASE_PORT}/{DATABASE_NAME}"
)

engine = create_engine(DATABASE_URL, echo=False)

templates = Jinja2Templates(directory=os.path.join(BASE_DIR, "templates"))


def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

@app.on_event("startup")
def on_startup():
    create_db_and_tables()

# Настройки JWT
SECRET_KEY = "your_secret_key_here"  # Замените на ваш секретный ключ
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# OAuth2 схема
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# Модели базы данных
class Record(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")
    user_name: str = Field(index=True)

    user_score: int = Field(default=0)
    last_updated: datetime = Field(default_factory=datetime.utcnow)

    user: Optional["User"] = Relationship(back_populates="records")

class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    created_at: datetime = Field(default_factory=datetime.utcnow)

    records: List["Record"] = Relationship(back_populates="user")

# Модели для токена
class Token(BaseModel):
    access_token: str
    token_type: str

# Функции для работы с пользователями
def get_user_by_name(username: str):
    with Session(engine) as session:
        user = session.exec(select(User).where(User.name == username)).first()
    return user

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta if expires_delta else timedelta(minutes=15))
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

# Функция для получения текущего пользователя
async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=401,
        detail="Не удалось проверить учетные данные",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    user = get_user_by_name(username)
    if user is None:
        raise credentials_exception
    return user

# Эндпоинты

# Эндпоинт для получения токена
@app.post("/token", response_model=Token, tags=["Authentication"])
async def login_for_access_token(username: str = Form(...)):
    user = get_user_by_name(username)
    if not user:
        raise HTTPException(
            status_code=401,
            detail="Неверное имя пользователя",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.name}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}


from pydantic import BaseModel

class UserCreate(BaseModel):
    name: str

# Эндпоинт для регистрации нового пользователя
@app.post("/register", response_model=Token, tags=["Users"])
def register_user(user_in: UserCreate):
    with Session(engine) as session:
        # Проверяем, существует ли пользователь с таким именем
        existing_user = session.exec(select(User).where(User.name == user_in.name)).first()
        if existing_user:
            raise HTTPException(status_code=400, detail="Пользователь с таким именем уже существует")

        user = User(name=user_in.name)
        session.add(user)
        session.commit()
        session.refresh(user)

    # Создаём токен доступа
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.name}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}



# Эндпоинт для отображения главной страницы
@app.get("/", response_class=HTMLResponse, tags=["Application"])
async def read_root(request: Request):
    with Session(engine) as session:
        records = session.exec(
            select(Record).order_by(Record.user_score.desc())
        ).all()
    return templates.TemplateResponse(
        "index.html",
        {"request": request, "records": records}
    )

# Эндпоинт для увеличения очков
@app.post("/increment_score/", tags=["Application"])
def increment_score(current_user: User = Depends(get_current_user)):
    with Session(engine) as session:
        record = session.exec(select(Record).where(Record.user_id == current_user.id)).first()
        if not record:
            record = Record(user_id=current_user.id, user_name=current_user.name, user_score=1)
            session.add(record)
        else:
            record.user_score += 1
            record.last_updated = datetime.utcnow()
        session.commit()
        session.refresh(record)
    return {"message": "Очки увеличены", "user_score": record.user_score}


# Эндпоинт для выхода из системы (не требуется, если вы не используете куки)


# Эндпоинт для получения списка пользователей
@app.get("/users/", response_model=List[User], tags=["Users"])
def read_users():
    with Session(engine) as session:
        users = session.exec(select(User)).all()
    return users

# Эндпоинт для получения информации о конкретном пользователе
@app.get("/users/{user_id}", response_model=User, tags=["Users"])
def read_user(user_id: int):
    with Session(engine) as session:
        user = session.get(User, user_id)
        if not user:
            raise HTTPException(status_code=404, detail="Пользователь не найден")
        return user


# Импортируем необходимые модули
from typing import List

# Определяем Pydantic-модель для записи
class RecordRead(BaseModel):
    user_name: str
    user_score: int

# Эндпоинт для получения списка записей
@app.get("/records/", response_model=List[RecordRead], tags=["Records"])
def read_records():
    with Session(engine) as session:
        records = session.exec(select(Record).order_by(Record.user_score.desc())).all()
    return records
