FROM python:3.11-slim

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir -r requirements.txt

# Add custom cert into certifi’s bundle
COPY publishedprices-co-il-chain.pem /tmp/
RUN cat /tmp/publishedprices-co-il-chain.pem >> $(python -m certifi)

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
