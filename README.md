# Outfitted: AI-Powered Fashion App

Outfitted is an AI-powered fashion application consisting of a modern Flutter mobile client and a FastAPI backend. It features AI wardrobe tagging, outfit generation, and a virtual try-on fitting room powered by IDM-VTON.

## Project Structure

- `app/`: Flutter mobile application (iOS/Android compatible).
- `backend/`: FastAPI backend powering the AI logic.

## Features

- **Smart Wardrobe**: Upload photos of your clothes and let AI automatically tag category, color, and style.
- **Outfit Suggestions**: Get intelligent outfit recommendations based on the weather, your wardrobe, and the occasion.
- **Virtual Try-On**: See how clothes look on you using advanced IDM-VTON diffusion models directly in the app.

## Setup Instructions

### Backend (Python/FastAPI)

1. Navigate to the `backend/` directory.
2. Create a virtual environment: `python -m venv venv`
3. Activate the virtual environment:
   - Windows: `venv\Scripts\activate`
   - Mac/Linux: `source venv/bin/activate`
4. Install dependencies: `pip install -r requirements.txt`
5. Copy `.env.example` to `.env` (if available) or create a `.env` file with the following variables:
   - `CLOUDINARY_CLOUD_NAME`
   - `CLOUDINARY_API_KEY`
   - `CLOUDINARY_API_SECRET`
   - `OPENROUTER_API_KEY` (for Gemini/Claude vision processing)
   - `REPLICATE_API_TOKEN` (for IDM-VTON virtual try-on)
   - `OPENWEATHERMAP_API_KEY`
6. Run the server: `uvicorn main:app --reload`

### App (Flutter)

1. Navigate to the `app/` directory.
2. Run `flutter pub get` to install dependencies.
3. Ensure you have a running emulator or connected device.
4. Run the app: `flutter run`

## Security Notes

Sensitive configuration files such as `.env` and local database files (`outfit_planner.db`) are ignored in Git to prevent accidental exposure of API keys and private data.
