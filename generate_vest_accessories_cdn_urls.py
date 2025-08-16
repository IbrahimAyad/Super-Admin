#!/usr/bin/env python3
"""
Generate CDN URLs for vest-tie-set and suspender-bowtie-set folders.
Handles both 'main.webp' and 'model.webp' naming conventions.
"""

import json
from pathlib import Path
from typing import Dict, List


def generate_vest_accessories_cdn_urls(base_url: str = "https://cdn.kctmenswear.com") -> Dict:
    """Generate CDN URLs for vest accessories."""
    
    cdn_mapping = {
        "base_url": base_url,
        "categories": {
            "suspender-bowtie-set": {},
            "vest-tie-set": {}
        }
    }
    
    # Define the target directories
    target_dirs = [
        ("vest-clean/menswear-accessories/suspender-bowtie-set", "suspender-bowtie-set"),
        ("vest-clean/vest-tie-set", "vest-tie-set")
    ]
    
    for local_dir, cdn_category in target_dirs:
        local_path = Path(local_dir)
        
        if not local_path.exists():
            print(f"Warning: {local_path} does not exist")
            continue
        
        # Find all product folders (those that are directories)
        product_folders = [d for d in local_path.iterdir() if d.is_dir()]
        
        for product_folder in sorted(product_folders):
            product_name = product_folder.name
            
            # Find all image files in this product folder
            image_files = []
            for ext in ['.webp', '.jpg', '.jpeg', '.png']:
                image_files.extend(product_folder.glob(f'*{ext}'))
            
            if not image_files:
                continue
            
            # Initialize product data
            cdn_mapping["categories"][cdn_category][product_name] = {
                "product_folder": product_name,
                "images": []
            }
            
            # Process each image file
            for image_file in sorted(image_files):
                image_name = image_file.name
                
                # Generate CDN URL
                cdn_url = f"{base_url}/menswear-accessories/{cdn_category}/{product_name}/{image_name}"
                
                # Determine image type
                image_type = "unknown"
                filename_lower = image_name.lower()
                
                if filename_lower.startswith('main.'):
                    image_type = "main"
                elif filename_lower.startswith('model.'):
                    image_type = "model"
                elif filename_lower.startswith('vest.'):
                    image_type = "vest"
                elif filename_lower.startswith('product.'):
                    image_type = "product"
                elif 'model' in filename_lower:
                    image_type = "model_variant"
                elif filename_lower.endswith('.jpg') and not filename_lower.startswith(('main.', 'model.', 'vest.', 'product.')):
                    image_type = "product_variant"
                
                cdn_mapping["categories"][cdn_category][product_name]["images"].append({
                    "image_name": image_name,
                    "image_type": image_type,
                    "local_path": str(image_file),
                    "cdn_url": cdn_url
                })
    
    return cdn_mapping


def main():
    print("Generating CDN URLs for vest accessories...")
    
    cdn_data = generate_vest_accessories_cdn_urls()
    
    if not cdn_data["categories"]["suspender-bowtie-set"] and not cdn_data["categories"]["vest-tie-set"]:
        print("No data found in target directories")
        return
    
    # Save to JSON file
    output_file = Path("vest_accessories_cdn_urls.json")
    with output_file.open('w', encoding='utf-8') as f:
        json.dump(cdn_data, f, indent=2, ensure_ascii=False)
    
    # Generate summary report
    total_images = 0
    print(f"\n{'='*80}")
    print("VEST ACCESSORIES CDN URLs SUMMARY")
    print(f"{'='*80}")
    
    for category, products in cdn_data["categories"].items():
        if not products:
            continue
            
        category_count = sum(len(product_data["images"]) for product_data in products.values())
        total_images += category_count
        print(f"\n{category.upper().replace('-', ' ')}: {category_count} images across {len(products)} products")
        
        for product_name, product_data in sorted(products.items()):
            image_count = len(product_data["images"])
            
            # Show image types
            image_types = [img["image_type"] for img in product_data["images"]]
            type_summary = ", ".join(sorted(set(image_types)))
            
            print(f"  {product_name}: {image_count} images ({type_summary})")
    
    print(f"\nTOTAL IMAGES: {total_images}")
    print(f"CDN mapping saved to: {output_file}")
    
    # Generate flat URL lists for each category
    for category, products in cdn_data["categories"].items():
        if not products:
            continue
            
        category_urls = []
        for product_name, product_data in products.items():
            for image_info in product_data["images"]:
                category_urls.append(image_info["cdn_url"])
        
        # Save category-specific URL list
        urls_file = Path(f"{category.replace('-', '_')}_cdn_urls.txt")
        with urls_file.open('w', encoding='utf-8') as f:
            for url in sorted(category_urls):
                f.write(f"{url}\n")
        
        print(f"{category} URLs saved to: {urls_file}")
    
    # Generate combined URL list
    all_urls = []
    for category, products in cdn_data["categories"].items():
        for product_name, product_data in products.items():
            for image_info in product_data["images"]:
                all_urls.append(image_info["cdn_url"])
    
    combined_file = Path("all_vest_accessories_cdn_urls.txt")
    with combined_file.open('w', encoding='utf-8') as f:
        for url in sorted(all_urls):
            f.write(f"{url}\n")
    
    print(f"All URLs combined saved to: {combined_file}")
    
    # Show first 10 URLs as examples
    print(f"\nFirst 10 CDN URLs (examples):")
    for i, url in enumerate(sorted(all_urls)[:10]):
        print(f"  {i+1}. {url}")
    
    if len(all_urls) > 10:
        print(f"  ... and {len(all_urls) - 10} more URLs")


if __name__ == "__main__":
    main()
