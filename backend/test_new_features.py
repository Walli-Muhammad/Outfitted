import httpx
import asyncio

async def test():
    # Let's wait a bit for server to start
    await asyncio.sleep(2)
    
    # 1. Test PATCH endpoint
    async with httpx.AsyncClient() as client:
        # Get all items for dev-user-1 to find one to patch
        r_get = await client.get("http://127.0.0.1:8000/wardrobe/items/dev-user-1")
        print("GET Wardrobe items status:", r_get.status_code)
        items = r_get.json()
        if items:
            item_id = items[0]["id"]
            print("Found item to patch:", item_id, "Current values:", {
                "type": items[0].get("type"),
                "color": items[0].get("color"),
                "style": items[0].get("style")
            })
            
            # Patch it
            patch_data = {
                "type": "jacket",
                "color": "black",
                "style": "rocker"
            }
            r_patch = await client.patch(
                f"http://127.0.0.1:8000/wardrobe/items/{item_id}",
                json=patch_data
            )
            print("PATCH status:", r_patch.status_code)
            print("PATCH response:", r_patch.json())
            
            # Verify update
            r_get_updated = await client.get("http://127.0.0.1:8000/wardrobe/items/dev-user-1")
            updated_items = r_get_updated.json()
            for ui in updated_items:
                if ui["id"] == item_id:
                    print("Updated values in DB:", {
                        "type": ui.get("type"),
                        "color": ui.get("color"),
                        "style": ui.get("style")
                    })
                    break
        else:
            print("No items found to patch. Please upload an item first.")

if __name__ == "__main__":
    asyncio.run(test())
