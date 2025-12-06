from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
fruits = [
    {"name": "Apple", "price": 1.2},
    {"name": "Banana", "price": 0.8},
    {"name": "Pineapple", "price": 2.2},
    {"name": "Cherry", "price": 3.5},
    {"name": "Orange", "price": 1.8},
    {"name": "Blueberry", "price": 2.5},
    {"name": "Lime", "price": 5.5},
    {"name": "Mango", "price": 2.4},
    {"name": "Kiwi", "price": 6.5},
    {"name": "Organinc Cucumber", "price": 2.0}
]


@app.get("/fruits")
def get_fruits():
    return {"fruits": fruits}
