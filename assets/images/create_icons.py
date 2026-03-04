#!/usr/bin/env python3
from PIL import Image, Image, Image, ImageDraw

def create_pyramid_icon(width, height, bg_color, fg_color):
    img = Image.new('RGBA', (width, height), bg_color if bg_color else (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = width // 2, height // 2

    # Large pyramid (center)
    points = [
        (cx, int(height * 0.2)),
        (cx - int(width * 0.23), int(height * 0.66)),
        (cx + int(width * 0.23), int(height * 0.66))
    ]
    draw.polygon(points, fill=fg_color)

    # Medium pyramid (left)
    points2 = [
        (int(width * 0.29), int(height * 0.31)),
        (int(width * 0.14), int(height * 0.66)),
        (int(width * 0.45), int(height * 0.66))
    ]
    draw.polygon(points2, fill=(230, 194, 0))

    # Small pyramid (right)
    points3 = [
        (int(width * 0.73), int(height * 0.39)),
        (int(width * 0.60), int(height * 0.66)),
        (int(width * 0.86), int(height * 0.66))
    ]
    draw.polygon(points3, fill=(204, 170, 0))

    return img

if __name__ == "__main__":
    # Create app icon (1024x1024)
    img = create_pyramid_icon(1024, 1024, (26, 26, 46, 255), (255, 215, 0))
    img.save('app_icon.png')
    print("Created app_icon.png")

    # Create foreground icon (transparent background)
    img = create_pyramid_icon(1024, 1024, None, (255, 215, 0))
    img.save('app_icon_foreground.png')
    print("Created app_icon_foreground.png")

    # Create splash logo (500x500)
    img = create_pyramid_icon(500, 500, None, (255, 215, 0))
    img.save('splash_logo.png')
    print("Created splash_logo.png")
