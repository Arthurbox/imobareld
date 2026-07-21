from PIL import Image

def main():
    path = r'assets\splash\logo.png'
    try:
        im = Image.open(path).convert("RGBA")
        
        # Detect non-transparent and non-black pixels
        data = im.getdata()
        mask = []
        for r, g, b, a in data:
            if a > 10 and (r > 15 or g > 15 or b > 15):
                mask.append(255)
            else:
                mask.append(0)
                
        mask_im = Image.new("L", im.size)
        mask_im.putdata(mask)
        bbox = mask_im.getbbox()
        
        if bbox:
            cropped = im.crop(bbox)
            
            # Canvas target size
            canvas_size = 1024
            # Target size for the logo inside the safe zone (around 52% of total canvas)
            target_logo_size = 535
            
            # Maintain aspect ratio
            w, h = cropped.size
            if w > h:
                new_w = target_logo_size
                new_h = int(h * (target_logo_size / w))
            else:
                new_h = target_logo_size
                new_w = int(w * (target_logo_size / h))
                
            resized_logo = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
            
            # Create new transparent canvas
            new_im = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
            
            # Center the logo
            offset = ((canvas_size - new_w) // 2, (canvas_size - new_h) // 2)
            new_im.paste(resized_logo, offset, resized_logo)
            
            new_im.save(path)
            print(f"Successfully scaled logo to {new_w}x{new_h} on {canvas_size}x{canvas_size} canvas.")
        else:
            print("Could not detect logo bounding box.")
            
    except Exception as e:
        print(f"Error scaling logo: {e}")

if __name__ == "__main__":
    main()
