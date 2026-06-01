import os
from dotenv import load_dotenv

load_dotenv()


async def run_tryon(
    human_image_url: str,
    garment_image_url: str,
    garment_description: str,
) -> str:
    """
    Runs the IDM-VTON model on Replicate to composite a garment onto a human photo.
    Uses version 0513734a (latest as of 2025-03-25).
    Input schema: garm_img, human_img, garment_des, crop, category, steps, seed.
    Reads REPLICATE_API_TOKEN lazily — never at module level.
    Raises an Exception with a clear message on failure.
    """
    import replicate  # imported here so missing package doesn't break startup

    api_token = os.getenv("REPLICATE_API_TOKEN", "")
    if not api_token or api_token.startswith("your-"):
        raise Exception(
            "REPLICATE_API_TOKEN is not configured. "
            "Add your token to .env to enable virtual try-on."
        )

    client = replicate.Client(api_token=api_token)

    output = client.run(
        "cuuupid/idm-vton:0513734a452173b8173e907e3a59d19a36266e55b48528559432bd21c7d7e985",
        input={
            "garm_img": garment_image_url,
            "human_img": human_image_url,
            "garment_des": garment_description,
            "crop": False,          # set True if image is not 3:4 ratio
            "category": "upper_body",
            "steps": 30,
            "seed": 42,
        },
    )

    if not output:
        raise Exception("Replicate returned an empty response.")

    # Latest version returns a single URI string (not a list)
    return str(output) if not isinstance(output, (list, tuple)) else str(output[0])
