import os
import cloudinary
import cloudinary.uploader
from fastapi import UploadFile
from dotenv import load_dotenv

# Load variables
load_dotenv()

# Initialize Cloudinary Configuration
cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET"),
    secure=True
)

async def upload_image(file: UploadFile) -> str:
    """
    Uploads a FastAPI UploadFile directly to Cloudinary.
    Applies transforms on-upload: auto-quality, auto-format, and max width of 1200px.
    Returns the secure HTTPS URL of the hosted resource.
    Falls back to a mock URL if Cloudinary API keys are not configured.
    """
    cloud_name = os.getenv("CLOUDINARY_CLOUD_NAME")
    api_key = os.getenv("CLOUDINARY_API_KEY")
    
    # Developer-friendly fallback bypass for easy local dry-runs
    if not api_key or "your-" in api_key or api_key == "":
        print("Cloudinary API keys not configured. Falling back to mock URL for local development.")
        # Return a mock URL representing the uploaded file
        return "https://res.cloudinary.com/demo/image/upload/v1570979139/sample.jpg"

    # Read the upload file contents into bytes
    content = await file.read()
    
    # Reset file read pointer for robustness
    await file.seek(0)
    
    # Upload to Cloudinary using standard SDK with the requested transformations
    response = cloudinary.uploader.upload(
        content,
        transformation=[
            {
                "width": 1200,
                "crop": "limit",
                "quality": "auto",
                "fetch_format": "auto"
            }
        ]
    )
    
    secure_url = response.get("secure_url")
    if not secure_url:
        raise ValueError("Cloudinary upload failed: secure_url was not returned.")
        
    return secure_url
