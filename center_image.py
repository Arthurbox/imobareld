from PIL import Image, ImageChops

def main():
    path = r'assets\splash\logoapp.png'
    try:
        im = Image.open(path)
        im = im.convert("RGBA")
        
        data = im.getdata()
        mask = []
        for r, g, b, a in data:
            if a > 10 and (r > 10 or g > 10 or b > 10):
                mask.append(255)
            else:
                mask.append(0)
                
        mask_im = Image.new("L", im.size)
        mask_im.putdata(mask)
        bbox = mask_im.getbbox()
        
        if bbox:
            cropped = im.crop(bbox)
            side = int(max(cropped.width, cropped.height) * 1.15)
            new_im = Image.new("RGBA", (side, side), (0,0,0,0))
            
            offset = ((side - cropped.width) // 2, (side - cropped.height) // 2)
            new_im.paste(cropped, offset)
            
            new_im.save(path)
            print("Successfully centered and saved the image.")
        else:
            print("Could not find logo bounding box.")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
