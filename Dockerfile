FROM public.ecr.aws/sam/build-python3.11:1.92.0
WORKDIR /app
COPY app.py /app
COPY requirements.txt /app

RUN pip install -r requirements.txt

CMD ["python", "app.py"]
