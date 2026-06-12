import httpx
import base64
import os
import cloudinary.uploader

async def run_tryon(human_image_url: str, garment_image_url: str, garment_description: str) -> str:
    api_key = os.getenv("DEEPINFRA_API_KEY", "").strip()
    if not api_key:
        raise Exception("DEEPINFRA_API_KEY is not configured.")

    async with httpx.AsyncClient(timeout=30.0) as client:
        garment_response = await client.get(garment_image_url)
        human_response = await client.get(human_image_url)

    garment_b64 = base64.b64encode(garment_response.content).decode("utf-8")
    human_b64 = base64.b64encode(human_response.content).decode("utf-8")

    prompt = (
        f"Virtual try-on: dress the person in image 2 with the {garment_description} shown in image 1. "
        f"Preserve the exact color, pattern, texture, and design details of the garment from image 1. "
        f"Keep the person's face, skin tone, pose, and background from image 2 completely unchanged. "
        f"The result should look like a natural, realistic fashion photograph."
    )

    async with httpx.AsyncClient(timeout=120.0) as client:
        response = await client.post(
            "https://api.deepinfra.com/v1/inference/black-forest-labs/FLUX-2-klein-9b",
            headers={
                "Authorization": f"bearer {api_key}",
                "Content-Type": "application/json"
            },
            json={
                "prompt": prompt,
                "input_image_1": f"data:image/jpeg;base64,{garment_b64}",
                "input_image_2": f"data:image/jpeg;base64,{human_b64}",
                "width": 768,
                "height": 1024,
                "output_format": "jpeg",
                "safety_tolerance": 3
            }
        )

    result = response.json()

    if "images" not in result or len(result["images"]) == 0:
        raise Exception(f"DeepInfra returned no images. Response: {result}")

    image_data_url = result["images"][0]
    if "," in image_data_url:
        image_data_url = image_data_url.split(",")[1]

    upload_result = cloudinary.uploader.upload(
        f"data:image/jpeg;base64,{image_data_url}",
        folder="tryons",
        quality="auto"
    )
    return upload_result["secure_url"]
