FROM python:3.11-slim

# ┌─────────────────────────────────────────────────────────────────────┐
# │  PLACEHOLDER IMAGE                                                   │
# │                                                                       │
# │  Replace this with your MATLAB Runtime image when ready:              │
# │    FROM mathworks/matlab-runtime:r2024a                               │
# │                                                                       │
# │  And replace process.py with your compiled MATLAB executable:         │
# │    COPY my_risk_scorer /app/my_risk_scorer                            │
# │    CMD ["/app/my_risk_scorer"]                                        │
# └─────────────────────────────────────────────────────────────────────┘

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "process.py"]
