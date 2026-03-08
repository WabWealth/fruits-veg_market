# Backend Deployment

The FastAPI backend code is in the main project repo:

- **Source:** `fruits-veg_market/backend-api/`
- **Deploy path on EC2:** `/home/ec2-user/app/` (per assignment layout)

This folder contains:
- `requirements.txt` - Python dependencies
- `fastapi.service` - systemd service file for production

The deploy script copies backend-api to `/home/ec2-user/app` and runs FastAPI via systemd.
Update `DATABASE_URL` in `backend-api/main.py` before deployment (or use env vars).
