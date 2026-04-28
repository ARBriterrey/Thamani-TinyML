# Production-Grade Deployment for Flask Orchestrator

This document outlines the transition from the built-in Flask development server to a production-ready WSGI (Web Server Gateway Interface) environment for the Thamani-TinyML system.

---

## 1. The Flask Framework: Strengths & Limitations

**Flask** is a "micro" web framework for Python. It is designed to be lightweight, modular, and easy to get started with.

### Strengths
- **Simplicity**: Minimal overhead and straightforward routing, making it ideal for microservices like our medical orchestrator.
- **Flexibility**: No strict data layer or template engine requirements; we have full control over how we handle binary sensor data.
- **Extensibility**: Easily integrates with Python's data science ecosystem (NumPy, Scipy, TensorFlow) which is critical for the ML-validation phase.

### Limitations (The "Development Server" Issue)
Flask comes with a built-in server (`werkzeug`), but it has critical limitations for production use:
- **Single-Threaded by Default**: It processes one request at a time. If one medical device is uploading a large binary file, other devices might be blocked or delayed.
- **Security**: It lacks the robust security hardening required to face the public internet directly.
- **Stability**: It is not designed to stay running for weeks or months under varying load; it can leak memory or become unresponsive if it encounters unexpected network behavior.

---

## 2. The Solution: WSGI Process Managers

To solve these limitations, we use a **WSGI Server**. This acts as a middleman between the external world (Nginx) and our Python code (Flask). It manages multiple "worker" processes to ensure concurrency and reliability.

### Option A: Gunicorn (Green Unicorn)
The most popular choice for modern Python web deployments. It follows a "Pre-fork" worker model.

| Pros | Cons |
|---|---|
| **Extremely Simple**: Easy to configure and run. | **Traditional**: Relies on processes rather than asynchronous threads. |
| **Stable**: Well-tested and handles failed worker processes automatically. | **Memory Usage**: Every worker process is a full Python instance. |
| **Low Latency**: Very thin layer over the application. | |

### Option B: uWSGI
A highly performant, feature-rich server often used in very complex or extreme-performance systems.

| Pros | Cons |
|---|---|
| **Performance**: Written in C; slightly faster than Gunicorn. | **Complexity**: Configuration is notoriously difficult and verbose. |
| **Rich Feature Set**: Includes its own caching, internal routing, and protocols. | **Heavyweight**: Overkill for a simple orchestrator. |

### Option C: Daphne / Uvicorn (ASGI)
Used for asynchronous frameworks (FastAPI/Quart).
- **Pros**: Handles thousands of concurrent idle connections (WebSockets).
- **Cons**: Requires rewriting Flask code to be `async`, which isn't necessary for our current REST-based file transfer.

---

## 3. Recommendation for Thamani

For the **Thamani-TinyML Orchestrator**, **Gunicorn** is the clear winner. It provides the perfect balance of production stability and simplicity. It allows us to run multiple workers (e.g., 4 workers) so one slow binary upload doesn't block other devices.

---

## 4. Implementation Guide (Gunicorn)

To upgrade the current orchestrator to a production setup, follow these three steps:

### Step 1: Update Dependencies
Add `gunicorn` to `/server-deployment/main-orchestrator/requirements.txt`:
```text
flask
docker
gunicorn
```

### Step 2: Update the Dockerfile
Modify the entry point in `/server-deployment/main-orchestrator/Dockerfile` to use the gunicorn command instead of calling Python directly.

**Current:**
`CMD ["python", "app.py"]`

**New (Production):**
`CMD ["gunicorn", "--workers", "4", "--bind", "0.0.0.0:5000", "--timeout", "300", "app:app"]`

*   `--workers 4`: Handles up to 4 concurrent heavy requests.
*   `--timeout 300`: Matches our Nginx config to allow long-running MATLAB binary processing.
*   `app:app`: Tells Gunicorn to look in `app.py` for the variable named `app`.

### Step 3: Rebuild Deployment
```bash
cd server-deployment
docker compose build main-orchestrator
docker compose up -d
```

Once running, the log warning will disappear, and the system will be ready for multi-device concurrent uploads.
