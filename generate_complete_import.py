#!/usr/bin/env python3
"""
Generate complete SQL import scripts from JSON files for all products
"""

import json
import uuid
from datetime import datetime

def load_json(filename):
    with open(filename, 'r') as f:
        return json.load(f)

def clean_product_name(slug):
    """Convert slug to proper product name"""
    words = slug.replace('-', ' ').split()
    # Capitalize each word, but keep certain words in uppercase
    uppercase_words = ['ii', 'iii', 'iv', 'v', 'vi', 'xl', 'xxl']
    result = []
    for word in words:
        if word.lower() in uppercase_words:
            result.append(word.upper())
        else:
            result.append(word.capitalize())
    return ' '.join(result)

def get_price_tier(price):
    """Get price tier based on price"""
    if price < 75: return 'TIER_1'
    elif price < 100: return 'TIER_2'  
    elif price < 125: return 'TIER_3'
    elif price < 150: return 'TIER_4'
    elif price < 200: return 'TIER_5'
    elif price < 250: return 'TIER_6'
    elif price < 300: return 'TIER_7'
    elif price < 400: return 'TIER_8'
    elif price < 500: return 'TIER_9'
    else: return 'TIER_10'

def get_color_from_name(name):
    """Extract color from product name"""
    colors = {
        'black': 'Black', 'white': 'White', 'grey': 'Grey', 'gray': 'Grey',
        'navy': 'Navy', 'blue': 'Blue', 'red': 'Red', 'pink': 'Pink',
        'green': 'Green', 'brown': 'Brown', 'tan': 'Tan', 'beige': 'Beige',
        'burgundy': 'Burgundy', 'purple': 'Purple', 'gold': 'Gold', 'silver': 'Silver',
        'orange': 'Orange', 'yellow': 'Yellow', 'mocha': 'Mocha', 'sage': 'Sage',
        'forest': 'Forest', 'smoked': 'Smoked', 'canyon': 'Canyon', 'clay': 'Clay',
        'sparkle': 'Sparkle', 'dusty': 'Dusty', 'rose': 'Rose', 'fuchsia': 'Fuchsia',
        'hunter': 'Hunter', 'burnt': 'Burnt', 'medium': 'Medium', 'dark': 'Dark',
        'light': 'Light'
    }
    
    name_lower = name.lower()
    found_colors = []
    for color_key, color_value in colors.items():
        if color_key in name_lower:
            found_colors.append(color_value)
    
    if found_colors:
        return ' '.join(found_colors)
    return 'Classic'

def get_color_family(color_name):
    """Get color family from color name"""
    color_map = {
        'Black': 'Black', 'Dark': 'Black',
        'White': 'White', 'Ivory': 'White', 
        'Grey': 'Grey', 'Gray': 'Grey', 'Silver': 'Grey',
        'Navy': 'Blue', 'Blue': 'Blue', 'Smoked Blue': 'Blue',
        'Red': 'Red', 'Burgundy': 'Red', 'Rose': 'Red',
        'Pink': 'Pink', 'Fuchsia': 'Pink', 'Dusty Rose': 'Pink',
        'Green': 'Green', 'Forest': 'Green', 'Sage': 'Green', 'Hunter': 'Green',
        'Brown': 'Brown', 'Mocha': 'Brown', 'Tan': 'Brown', 'Canyon': 'Brown', 'Clay': 'Brown',
        'Orange': 'Orange', 'Burnt Orange': 'Orange',
        'Yellow': 'Yellow', 'Gold': 'Yellow',
        'Purple': 'Purple'
    }
    
    for key, family in color_map.items():
        if key.lower() in color_name.lower():
            return family
    return 'Multi'

def generate_fall_2025_sql():
    """Generate SQL for Fall 2025 Collection"""
    data = load_json('fall_2025_cdn_urls.json')
    
    sql_lines = []
    sql_lines.append("-- Complete Fall 2025 Collection Import")
    sql_lines.append("-- Auto-generated from JSON data\n")
    
    # Category pricing
    prices = {
        'double-breasted-suits': 449.99,
        'suits': 399.99,
        'stretch-suits': 399.99,
        'tuxedos': 499.99,
        'mens-shirts': 79.99
    }
    
    # Category mapping
    category_names = {
        'double-breasted-suits': 'Double-Breasted Suits',
        'suits': 'Suits',
        'stretch-suits': 'Stretch Suits',
        'tuxedos': 'Tuxedos',
        'mens-shirts': 'Mens Shirts'
    }
    
    product_count = 0
    
    for category_slug, products in data['categories'].items():
        category = category_names.get(category_slug, category_slug.replace('-', ' ').title())
        base_price = prices.get(category_slug, 399.99)
        
        for product_slug, product_data in products.items():
            product_count += 1
            product_name = clean_product_name(product_slug)
            product_id = str(uuid.uuid4())
            sku = f"F25-{category_slug[:3].upper()}-{product_count:03d}"
            
            color_name = get_color_from_name(product_name)
            color_family = get_color_family(color_name)
            
            # Get images
            hero_image = ''
            gallery_images = []
            for img in product_data.get('images', []):
                if 'main' in img['image_name'] or 'lifestyle' in img['image_name']:
                    hero_image = img['cdn_url']
                else:
                    gallery_images.append(img['cdn_url'])
            
            if not hero_image and gallery_images:
                hero_image = gallery_images[0]
                gallery_images = gallery_images[1:]
            
            # Build images JSON
            images_json = '{'
            if hero_image:
                images_json += f'"hero": {{"url": "{hero_image}"}}'
            if gallery_images:
                gallery_json = ', '.join([f'{{"url": "{url}"}}' for url in gallery_images[:3]])
                images_json += f', "gallery": [{gallery_json}]'
            images_json += '}'
            
            sql_lines.append(f"""
INSERT INTO products_enhanced (
    id, name, sku, handle, slug, style_code, season, collection,
    category, subcategory, price_tier, base_price, compare_at_price,
    color_name, color_family, materials, fit_type, images, description,
    status, meta_title, meta_description, meta_keywords, og_title,
    og_description, search_terms, url_slug, is_indexable, sitemap_priority,
    created_at, updated_at
) VALUES (
    '{product_id}',
    '{product_name}',
    '{sku}',
    '{product_slug}',
    '{product_slug}',
    '{sku}',
    'Fall 2025',
    'Fall 2025 Collection',
    '{category}',
    'Premium Collection',
    '{get_price_tier(base_price)}',
    {base_price},
    {base_price + 150},
    '{color_name}',
    '{color_family}',
    '{{"primary": "Premium Wool Blend", "lining": "Viscose"}}',
    'Modern Fit',
    '{images_json}',
    'Premium {product_name} from our Fall 2025 Collection. Expertly tailored with attention to detail.',
    'active',
    '{product_name} | {category} | KCT Menswear',
    'Shop {product_name} at ${base_price}. Fall 2025 Collection. Free shipping.',
    ARRAY['{category.lower()}', '{color_name.lower()}', 'fall 2025', 'menswear'],
    '{product_name} - Fall 2025',
    'Elegant {product_name} perfect for formal occasions.',
    '{product_slug} {category.lower()} {color_name.lower()} formal',
    '{product_slug}',
    true,
    0.8,
    NOW(),
    NOW()
);""")
    
    return '\n'.join(sql_lines)

def generate_accessories_sql():
    """Generate SQL for Accessories Collection"""
    data = load_json('vest_accessories_cdn_urls.json')
    
    sql_lines = []
    sql_lines.append("\n\n-- Complete Accessories Collection Import")
    sql_lines.append("-- Auto-generated from JSON data\n")
    
    product_count = 0
    
    for category_slug, products in data['categories'].items():
        for product_slug, product_data in products.items():
            product_count += 1
            product_name = clean_product_name(product_slug)
            
            if 'suspender' in product_slug:
                sku_prefix = 'ACC-SBS'
                subcategory = 'Suspender Sets'
                fit_type = 'One Size'
            else:
                sku_prefix = 'ACC-VTS'
                subcategory = 'Vest Sets'
                fit_type = 'XS-6XL'
            
            product_id = str(uuid.uuid4())
            sku = f"{sku_prefix}-{product_count:03d}"
            
            color_name = get_color_from_name(product_name)
            color_family = get_color_family(color_name)
            
            # Get images
            hero_image = ''
            gallery_images = []
            for img in product_data.get('images', []):
                if 'main' in img['image_name'] or 'model' in img['image_name']:
                    hero_image = img['cdn_url']
                else:
                    gallery_images.append(img['cdn_url'])
            
            if not hero_image and gallery_images:
                hero_image = gallery_images[0]
                gallery_images = gallery_images[1:]
            
            # Build images JSON
            images_json = '{'
            if hero_image:
                images_json += f'"hero": {{"url": "{hero_image}"}}'
            if gallery_images:
                gallery_json = ', '.join([f'{{"url": "{url}"}}' for url in gallery_images[:2]])
                images_json += f', "gallery": [{gallery_json}]'
            images_json += '}'
            
            sql_lines.append(f"""
INSERT INTO products_enhanced (
    id, name, sku, handle, slug, style_code, season, collection,
    category, subcategory, price_tier, base_price, compare_at_price,
    color_name, color_family, materials, fit_type, images, description,
    status, meta_title, meta_description, meta_keywords, og_title,
    og_description, search_terms, url_slug, is_indexable, sitemap_priority,
    created_at, updated_at
) VALUES (
    '{product_id}',
    '{product_name}',
    '{sku}',
    '{product_slug}',
    '{product_slug}',
    '{sku}',
    'All Season',
    'Accessories Collection',
    'Accessories',
    '{subcategory}',
    'TIER_1',
    49.99,
    79.99,
    '{color_name}',
    '{color_family}',
    '{{"primary": "Premium Microfiber", "hardware": "Metal"}}',
    '{fit_type}',
    '{images_json}',
    'Elegant {product_name} perfect for weddings, proms, and formal events. Premium quality accessories.',
    'active',
    '{product_name} | Formal Accessories | KCT Menswear',
    'Shop {product_name} at $49.99. Perfect for formal events. Same-day shipping.',
    ARRAY['accessories', '{subcategory.lower()}', '{color_name.lower()}', 'formal', 'wedding'],
    '{product_name} - Premium Accessories',
    'Premium {product_name} for formal occasions.',
    '{product_slug} accessories formal wedding',
    '{product_slug}',
    true,
    0.7,
    NOW(),
    NOW()
);""")
    
    return '\n'.join(sql_lines)

# Generate complete SQL
complete_sql = generate_fall_2025_sql() + generate_accessories_sql()

# Add summary
complete_sql += """

-- Verify import
SELECT category, subcategory, COUNT(*) as count, MIN(base_price) as min_price, MAX(base_price) as max_price
FROM products_enhanced 
WHERE sku LIKE 'F25-%' OR sku LIKE 'ACC-%'
GROUP BY category, subcategory
ORDER BY category, subcategory;
"""

# Write to file
with open('sql/import-all-products-complete.sql', 'w') as f:
    f.write(complete_sql)

print("Generated complete import script with all products!")
print("File: sql/import-all-products-complete.sql")