# Deployment Guide - GDG Hackathon Project

## Quick Overview
- **Backend**: Flask Python app → Deploy to [Render](https://render.com)
- **Frontend**: Flutter Web app → Deploy to [Vercel](https://vercel.com)

---

## Part 1: Deploy Backend to Render

### Step 1: Prepare Backend for Deployment

1. Push your code to GitHub:
```bash
git add .
git commit -m "Setup deployment configuration"
git push origin main
```

2. Ensure you have a `.env` file with required variables in the backend folder:
```
FLASK_ENV=production
FLASK_DEBUG=False
GOOGLE_MAPS_API_KEY=your_actual_key_here
FIREBASE_API_KEY=your_actual_key_here
```

⚠️ **IMPORTANT**: Never commit `.env` to GitHub. The `.env.example` is already in gitignore.

### Step 2: Create Render Account
1. Go to [https://render.com](https://render.com)
2. Sign up with your GitHub account
3. Authorize Render to access your repositories

### Step 3: Deploy Backend Service
1. Click "New +" → "Web Service"
2. Select your `gdg_hackathon` repository
3. **Configure service**:
   - **Name**: `gdg-backend`
   - **Root Directory**: `backend`
   - **Runtime**: Python 3
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `python app.py`
   - **Plan**: Free (or paid if you want better uptime)

4. **Add Environment Variables** (from your `.env`):
   - `FLASK_ENV` = `production`
   - `FLASK_DEBUG` = `False`
   - `GOOGLE_MAPS_API_KEY` = your_key
   - `FIREBASE_API_KEY` = your_key

5. Click "Create Web Service"
6. Wait for deployment to complete
7. **Copy your backend URL** (will look like `https://gdg-backend-xxxx.onrender.com`)

---

## Part 2: Deploy Frontend to Vercel

### Step 1: Create Vercel Account
1. Go to [https://vercel.com](https://vercel.com)
2. Sign up with your GitHub account
3. Authorize Vercel to access your repositories

### Step 2: Create Project
1. Click "Add New..." → "Project"
2. Select your `gdg_hackathon` repository
3. **Configure project**:
   - **Framework Preset**: Other (Flutter is not officially supported, but we'll build web)
   - **Root Directory**: `flutter_frontend`
   - **Build Command**: `flutter build web --release`
   - **Output Directory**: `build/web`

### Step 3: Add Environment Variables
1. Go to **Settings** → **Environment Variables**
2. Add the following:
   - `BACKEND_BASE_URL` = `https://your-backend-url-from-render.onrender.com`
   - `GOOGLE_MAPS_API_KEY` = your_key
   - `GEMINI_API_KEY` = your_key (if applicable)

### Step 4: Deploy
1. Click "Deploy"
2. Wait for the build to complete
3. **Copy your frontend URL** (will look like `https://gdg-frontend-xxxx.vercel.app`)

---

## Part 3: Integration & Testing

### Verify Backend
1. Open: `https://your-backend-url/api/health`
2. You should see: `{"ok": true, "graph_loaded": false, "osmnx_available": false}`

### Verify Frontend
1. Open your frontend URL in a browser
2. Test the login/signup functionality
3. Try creating an emergency zone to test backend communication

### Fix CORS Issues (if any)
If you see CORS errors in browser console, the backend already handles this. But you can verify:
- Backend has `@app.after_request` that adds CORS headers
- All endpoints allow cross-origin requests

---

## Part 4: Environment Variables Reference

### Backend (.env)
```
FLASK_ENV=production
FLASK_DEBUG=False
GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_KEY
FIREBASE_API_KEY=YOUR_FIREBASE_API_KEY
```

### Frontend (Vercel Environment Variables)
```
BACKEND_BASE_URL=https://your-backend-url.onrender.com
GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_KEY
GEMINI_API_KEY=YOUR_GEMINI_API_KEY
```

---

## Part 5: Get Your API Keys

### Google Maps API
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project
3. Enable Maps JavaScript API
4. Create an API key
5. Restrict it to browser and add your Vercel domain

### Firebase
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Get your Web API Key from Project Settings
4. Download service account key (for backend)

### Gemini API (Optional)
1. Go to [Google AI Studio](https://aistudio.google.com/apikey)
2. Create an API key
3. Add to Vercel environment variables

---

## Troubleshooting

### Backend Issues
- Check Render logs: Dashboard → gdg-backend → Logs
- Ensure PORT environment variable is read (should auto-set on Render)
- Firebase features work only if serviceAccountKey.json exists

### Frontend Issues
- Check Vercel logs: Dashboard → gdg-frontend → Deployments
- Ensure Flutter web is being built: `flutter build web --release`
- Verify environment variables are set in Vercel dashboard

### CORS Errors
- Backend CORS headers are already configured
- Ensure frontend uses correct BACKEND_BASE_URL

---

## Final Links

After deployment:
- **Backend API**: `https://your-backend-url.onrender.com`
- **Frontend Website**: `https://your-frontend.vercel.app`

**Complete Integration URL**: Just open the frontend URL in your browser!

---

## Useful Commands for Local Testing

```bash
# Backend
cd backend
pip install -r requirements.txt
python app.py

# Frontend
cd flutter_frontend
flutter pub get
flutter run -d chrome  # Run in Chrome for web testing
```

---

## Next Steps
1. Set up custom domain (optional) on both Render and Vercel
2. Enable HTTPS (both platforms do this by default)
3. Set up monitoring and alerts
4. Configure CI/CD for automatic deployments on git push
