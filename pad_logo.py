from PIL import Image

def pad_image(input_path, output_path, padding_percent=0.2):
    img = Image.open(input_path).convert("RGBA")
    
    # Calculate new size
    width, height = img.size
    new_width = int(width * (1 + padding_percent))
    new_height = int(height * (1 + padding_percent))
    
    # Create a new transparent image (or solid dark color if preferred)
    # The current logo seems to have a black background in the center
    # Let's use a solid dark background color to match the edge of the logo
    # For a circular logo, it's safer to use transparency if the logo is a circle, 
    # but her screenshot shows a solid dark background around the logo.
    # Let's just sample the top-left pixel color as the background color
    bg_color = img.getpixel((0, 0))
    if len(bg_color) == 4 and bg_color[3] == 0:
        # It's transparent
        new_img = Image.new("RGBA", (new_width, new_height), (0, 0, 0, 0))
    else:
        # Use the sampled background color
        new_img = Image.new("RGBA", (new_width, new_height), bg_color)
    
    # Paste the original image into the center
    x = (new_width - width) // 2
    y = (new_height - height) // 2
    new_img.paste(img, (x, y), img)
    
    # Save the output
    new_img.save(output_path)
    print(f"Saved padded image to {output_path}")

# Run padding
input_file = r"C:\proyectos\APP KOPYTRADING\public\logo-kopytrading.png"
output_file = r"C:\proyectos\APP KOPYTRADING\MATERIAL REDES\perfil_facebook_ajustado.png"
pad_image(input_file, output_file, padding_percent=0.3)
