#!/usr/bin/env python3

# Fix apostrophe escaping in SQL file
with open('IMPORT-GALLERY-IMAGES-FIXED.sql', 'r') as f:
    content = f.read()

# Replace problematic apostrophes in category names
replacements = [
    ("'Men's Suits'", "'Men''s Suits'"),
    ("'Men's Dress Shirts'", "'Men''s Dress Shirts'"),
    ("'Men'S Double", "'Men''S Double"),  # Fix any capitalization issues
    ("'Men'S ", "'Men''s "),  # Fix apostrophe in alt text
]

for old, new in replacements:
    content = content.replace(old, new)

# Write fixed content
with open('IMPORT-GALLERY-IMAGES-FINAL.sql', 'w') as f:
    f.write(content)

print("✅ Fixed apostrophe escaping in SQL file")
print("📄 Output: IMPORT-GALLERY-IMAGES-FINAL.sql")