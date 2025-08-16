#!/usr/bin/env python3
"""
Generate CDN URLs for all Fall 2025 images based on Cloudflare pattern.

Based on the provided URLs, the pattern appears to be:
https://cdn.kctmenswear.com/{category}/{product-name}/{image-name}.webp

This script scans the Fall 2025 folder and generates the correct CDN URLs.
"""

import json
from pathlib import Path
from typing import Dict, List


def generate_cdn_urls(base_url: str = "https://cdn.kctmenswear.com") -> Dict:
    """Generate CDN URLs for all Fall 2025 images."""
    fall_2025_path = Path("Fall 2025")
    
    if not fall_2025_path.exists():
        print("Error: Fall 2025 directory not found")
        return {}
    
    cdn_mapping = {
        "base_url": base_url,
        "categories": {}
    }
    
    # Category mapping from folder names to CDN paths
    category_mapping = {
        "mens-shirts": "mens-shirts",
        "double-breasted-suits": "double-breasted-suits", 
        "stretch-suits": "stretch-suits",
        "suits": "suits",
        "tuxedos": "tuxedos"
    }
    
    # Find all WebP files
    webp_files = list(fall_2025_path.rglob("*.webp"))
    
    for webp_file in sorted(webp_files):
        # Get relative path from Fall 2025
        rel_path = webp_file.relative_to(fall_2025_path)
        path_parts = rel_path.parts
        
        if len(path_parts) < 3:
            continue  # Skip if not in expected structure
        
        category_folder = path_parts[0]
        
        # Handle nested mens-shirts structure
        if category_folder == "mens-shirts" and len(path_parts) == 4:
            # Handle Fall 2025/mens-shirts/mens-shirts/product/image.webp
            if path_parts[1] == "mens-shirts":
                product_name = path_parts[2]
                image_name = path_parts[3]
            else:
                product_name = path_parts[1]
                image_name = path_parts[2]
        else:
            # Standard structure: Fall 2025/category/product/image.webp
            product_name = path_parts[1]
            image_name = path_parts[2]
        
        # Get CDN category name
        cdn_category = category_mapping.get(category_folder, category_folder)
        
        # Generate CDN URL
        cdn_url = f"{base_url}/{cdn_category}/{product_name}/{image_name}"
        
        # Organize by category
        if cdn_category not in cdn_mapping["categories"]:
            cdn_mapping["categories"][cdn_category] = {}
        
        if product_name not in cdn_mapping["categories"][cdn_category]:
            cdn_mapping["categories"][cdn_category][product_name] = {
                "product_folder": product_name,
                "images": []
            }
        
        cdn_mapping["categories"][cdn_category][product_name]["images"].append({
            "image_name": image_name,
            "local_path": str(webp_file),
            "cdn_url": cdn_url
        })
    
    return cdn_mapping


def main():
    print("Generating CDN URLs for Fall 2025 images...")
    
    cdn_data = generate_cdn_urls()
    
    if not cdn_data:
        return
    
    # Save to JSON file
    output_file = Path("fall_2025_cdn_urls.json")
    with output_file.open('w', encoding='utf-8') as f:
        json.dump(cdn_data, f, indent=2, ensure_ascii=False)
    
    # Generate summary report
    total_images = 0
    print(f"\n{'='*80}")
    print("FALL 2025 CDN URLs SUMMARY")
    print(f"{'='*80}")
    
    for category, products in cdn_data["categories"].items():
        category_count = sum(len(product_data["images"]) for product_data in products.values())
        total_images += category_count
        print(f"\n{category.upper()}: {category_count} images across {len(products)} products")
        
        for product_name, product_data in sorted(products.items()):
            image_count = len(product_data["images"])
            print(f"  {product_name}: {image_count} images")
    
    print(f"\nTOTAL IMAGES: {total_images}")
    print(f"CDN mapping saved to: {output_file}")
    
    # Generate flat URL list for easy copying
    all_urls = []
    for category, products in cdn_data["categories"].items():
        for product_name, product_data in products.items():
            for image_info in product_data["images"]:
                all_urls.append(image_info["cdn_url"])
    
    # Save flat URL list
    urls_file = Path("fall_2025_all_cdn_urls.txt")
    with urls_file.open('w', encoding='utf-8') as f:
        for url in sorted(all_urls):
            f.write(f"{url}\n")
    
    print(f"All URLs list saved to: {urls_file}")
    
    # Show first 10 URLs as examples
    print(f"\nFirst 10 CDN URLs (examples):")
    for i, url in enumerate(sorted(all_urls)[:10]):
        print(f"  {i+1}. {url}")
    
    if len(all_urls) > 10:
        print(f"  ... and {len(all_urls) - 10} more URLs")


if __name__ == "__main__":
    main()
