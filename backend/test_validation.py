import unittest
from unittest.mock import MagicMock, AsyncMock, patch
import asyncio
from fastapi import HTTPException

# Add parent path to import correctly
import sys
sys.path.append(".")
from services.vision import tag_garment

class TestVisionValidation(unittest.IsolatedAsyncioTestCase):
    @patch("httpx.AsyncClient.post")
    @patch("os.getenv")
    async def test_non_clothing_validation(self, mock_getenv, mock_post):
        # Configure env key so it makes the HTTP call
        mock_getenv.return_value = "fake-key"
        
        # Mock response from OpenRouter/Gemini returning non-clothing item
        # Since client.post is async, its return value (the coroutine result) is mock_response.
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.raise_for_status = MagicMock()
        mock_response.json = MagicMock(return_value={
            "choices": [
                {
                    "message": {
                        "content": '{"type": "keyboard", "color": "black", "style": "mechanical"}'
                    }
                }
            ]
        })
        
        # mock_post is the mock for client.post. When awaited, it should return mock_response.
        mock_post.return_value = mock_response
        
        # Verify that HTTPException is raised with 400 status and correct message
        with self.assertRaises(HTTPException) as ctx:
            await tag_garment("http://example.com/keyboard.jpg")
            
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertEqual(ctx.exception.detail, "This doesn't look like a clothing item. Please photograph a garment.")
        print("Test passed! HTTPException raised with status 400 and expected message.")

if __name__ == "__main__":
    unittest.main()
