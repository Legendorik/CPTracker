FROM python:3.9.4-slim

COPY requirements.txt requirements.txt

#RUN apt-get update && apt-get install -y gcc libpq-dev git && pip install --upgrade pip
RUN apt-get update && pip install --upgrade pip

ADD . /src

RUN pip install -r requirements.txt

WORKDIR /src

CMD ["python", "server.py"]
