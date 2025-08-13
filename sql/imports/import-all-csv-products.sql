-- SQL Script to Import All CSV Products into Supabase Database
-- Generated: 2025-08-12T16:40:10.371Z
-- Total products to import: 233
--
-- This script will add 233 new products from CSV files
-- No conflicts with existing products (different catalogs)

BEGIN;

-- Insert products from CSV files

-- Product 1: White Nan A Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0001',
    'White Nan A Vest And Tie Set',
    'Imported from sets CSV - White Nan A Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_10-a-white-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-a-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 2: Nan Blush Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0002',
    'Nan Blush Vest And Tie Set',
    'Imported from sets CSV - Nan Blush Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_blush-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-blush-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 3: Charcoal Nan Bowtie Wedding Bundle
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0003',
    'Charcoal Nan Bowtie Wedding Bundle',
    'Imported from sets CSV - Charcoal Nan Bowtie Wedding Bundle',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_charcoal-bowtie-wedding-bundle_5.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-bowtie-wedding-bundle',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 4: Pink Nan Bubblegum Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0004',
    'Pink Nan Bubblegum Vest And Tie Set',
    'Imported from sets CSV - Pink Nan Bubblegum Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_bubblegum-pink-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-bubblegum-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 5: Nan Canary Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0005',
    'Nan Canary Vest And Tie Set',
    'Imported from sets CSV - Nan Canary Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_canary-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-canary-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 6: Blue Nan Carolina Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0006',
    'Blue Nan Carolina Vest And Tie Set',
    'Imported from sets CSV - Blue Nan Carolina Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_carolina-blue-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-carolina-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 7: Brown Nan Chocolate Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0007',
    'Brown Nan Chocolate Vest And Tie Set',
    'Imported from sets CSV - Brown Nan Chocolate Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_chocolate-brown-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-chocolate-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 8: Nan Cinnamon Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0008',
    'Nan Cinnamon Vest And Tie Set',
    'Imported from sets CSV - Nan Cinnamon Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_cinnamon-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-cinnamon-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 9: Nan Coral Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0009',
    'Nan Coral Vest And Tie Set',
    'Imported from sets CSV - Nan Coral Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_coral-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-coral-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 10: Grey Nan Dark Suspender Bow Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0010',
    'Grey Nan Dark Suspender Bow Tie Set',
    'Imported from sets CSV - Grey Nan Dark Suspender Bow Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_dark-grey-suspender-bow-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-dark-suspender-bow-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 11: Rose Nan Dusty Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0011',
    'Rose Nan Dusty Vest And Tie Set',
    'Imported from sets CSV - Rose Nan Dusty Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_dusty-rose-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-dusty-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 12: Green Nan Emerald Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0012',
    'Green Nan Emerald Vest And Tie Set',
    'Imported from sets CSV - Green Nan Emerald Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_emerald-green-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-emerald-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 13: Green Nan Forest Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0013',
    'Green Nan Forest Vest And Tie Set',
    'Imported from sets CSV - Green Nan Forest Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_forest-green-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-forest-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 14: Blue Nan French Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0014',
    'Blue Nan French Vest And Tie Set',
    'Imported from sets CSV - Blue Nan French Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_french-blue-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-french-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 15: Rose Nan French Wedding Bundle
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0015',
    'Rose Nan French Wedding Bundle',
    'Imported from sets CSV - Rose Nan French Wedding Bundle',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_french-rose-wedding-bundle_4.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-french-wedding-bundle',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 16: Nan Fuchsia Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0016',
    'Nan Fuchsia Vest And Tie Set',
    'Imported from sets CSV - Nan Fuchsia Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_fuchsia-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-fuchsia-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 17: Green Nan Lettuce Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0017',
    'Green Nan Lettuce Vest And Tie Set',
    'Imported from sets CSV - Green Nan Lettuce Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_lettuce-green-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-lettuce-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 18: Green Nan Kiwi Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0018',
    'Green Nan Kiwi Vest And Tie Set',
    'Imported from sets CSV - Green Nan Kiwi Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_kiwi-green-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-kiwi-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 19: Blue Nan Light Suspender Bow Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0019',
    'Blue Nan Light Suspender Bow Tie Set',
    'Imported from sets CSV - Blue Nan Light Suspender Bow Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_light-blue-suspender-bow-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-light-suspender-bow-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 20: Pink Nan Light Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0020',
    'Pink Nan Light Vest And Tie Set',
    'Imported from sets CSV - Pink Nan Light Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_light-pink-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-light-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 21: Green Nan Lime Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0021',
    'Green Nan Lime Vest And Tie Set',
    'Imported from sets CSV - Green Nan Lime Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_lime-green-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-lime-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 22: Red Nan Medium Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0022',
    'Red Nan Medium Vest And Tie Set',
    'Imported from sets CSV - Red Nan Medium Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_medium-purple-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-medium-vest-and-tie-set',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 23: Nan Mocha Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0023',
    'Nan Mocha Vest And Tie Set',
    'Imported from sets CSV - Nan Mocha Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_mocha-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-mocha-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 24: Green Nan Mermaid Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0024',
    'Green Nan Mermaid Vest And Tie Set',
    'Imported from sets CSV - Green Nan Mermaid Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_mermaid-green-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-mermaid-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 25: White Nan Off Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0025',
    'White Nan Off Vest And Tie Set',
    'Imported from sets CSV - White Nan Off Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_off-white-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-off-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 26: Blue Nan Powder Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0026',
    'Blue Nan Powder Vest And Tie Set',
    'Imported from sets CSV - Blue Nan Powder Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_powder-blue-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-powder-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 27: Nan Rust Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0027',
    'Nan Rust Vest And Tie Set',
    'Imported from sets CSV - Nan Rust Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_rust-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-rust-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 28: Orange Nan Salmon Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0028',
    'Orange Nan Salmon Vest And Tie Set',
    'Imported from sets CSV - Orange Nan Salmon Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_salmon-orange-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-salmon-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 29: Purple Nan Suspender Bow Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0029',
    'Purple Nan Suspender Bow Tie Set',
    'Imported from sets CSV - Purple Nan Suspender Bow Tie Set',
    95,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_brown-suspender-bow-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-suspender-bow-tie-set',
        'total_images', 8,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 30: Red Nan True Suspender Bow Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0030',
    'Red Nan True Suspender Bow Tie Set',
    'Imported from sets CSV - Red Nan True Suspender Bow Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_true-red-suspender-bow-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-true-suspender-bow-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 31: Gold Nan True Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0031',
    'Gold Nan True Vest And Tie Set',
    'Imported from sets CSV - Gold Nan True Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_true-gold-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-true-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 32: Nan Turquoise Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0032',
    'Nan Turquoise Vest And Tie Set',
    'Imported from sets CSV - Nan Turquoise Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_turquoise-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-turquoise-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 33: Yellow Nan Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0033',
    'Yellow Nan Vest And Tie Set',
    'Imported from sets CSV - Yellow Nan Vest And Tie Set',
    95,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_olive-green-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-vest-and-tie-set',
        'total_images', 15,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 34: Nan Wine Suspender Bow Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0034',
    'Nan Wine Suspender Bow Tie Set',
    'Imported from sets CSV - Nan Wine Suspender Bow Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_wine-suspender-bow-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-wine-suspender-bow-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 35: Black Nan Wedding Bundle Bowtie OR Tie
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0035',
    'Black Nan Wedding Bundle Bowtie OR Tie',
    'Imported from sets CSV - Black Nan Wedding Bundle Bowtie OR Tie',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_wedding-bundle-black-bowtie-or-tie_6.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-wedding-bundle-bowtie-or-tie',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 36: Burgundy Nan Wine Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0036',
    'Burgundy Nan Wine Vest And Tie Set',
    'Imported from sets CSV - Burgundy Nan Wine Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_04/nan_wine-burgundy-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'nan-wine-vest-and-tie-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 37: Royal Blue Sparkle Vest And Tie Sparkle Vest And Bowtie
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0037',
    'Royal Blue Sparkle Vest And Tie Sparkle Vest And Bowtie',
    'Imported from sets CSV - Royal Blue Sparkle Vest And Tie Sparkle Vest And Bowtie',
    70,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/sparkle-vest-and-tie_red-sparkle-vest-and-bowtie_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'sparkle-vest-and-tie-sparkle-vest-and-bowtie',
        'total_images', 3,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 38: Black Suspender Set Suspender Bow Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0038',
    'Black Suspender Set Suspender Bow Tie Set',
    'Imported from sets CSV - Black Suspender Set Suspender Bow Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/suspender-set_black-suspender-bow-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'suspender-set-suspender-bow-tie-set',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 39: Rose Tie And Bowtie French Wedding Bundle
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0039',
    'Rose Tie And Bowtie French Wedding Bundle',
    'Imported from sets CSV - Rose Tie And Bowtie French Wedding Bundle',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/tie-and-bowtie_french-rose-wedding-bundle_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'tie-and-bowtie-french-wedding-bundle',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 40: Vest And Tie Aqua Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0040',
    'Vest And Tie Aqua Vest And Tie Set',
    'Imported from sets CSV - Vest And Tie Aqua Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/vest-and-tie_aqua-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'vest-and-tie-aqua-vest-and-tie-set',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 41: Red Vest And Tie Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0041',
    'Red Vest And Tie Vest And Tie Set',
    'Imported from sets CSV - Red Vest And Tie Vest And Tie Set',
    70,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/vest-and-tie_royal-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'vest-and-tie-vest-and-tie-set',
        'total_images', 4,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 42: Blue Vest Tie Baby Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0042',
    'Blue Vest Tie Baby Vest And Tie Set',
    'Imported from sets CSV - Blue Vest Tie Baby Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/vest-tie_baby-blue-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'vest-tie-baby-vest-and-tie-set',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 43: Yellow Vest Tie Chartreuse Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0043',
    'Yellow Vest Tie Chartreuse Vest And Tie Set',
    'Imported from sets CSV - Yellow Vest Tie Chartreuse Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/vest-tie_chartreuse-yellow-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'vest-tie-chartreuse-vest-and-tie-set',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 44: Purple Vest Tie Deep Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0044',
    'Purple Vest Tie Deep Vest And Tie Set',
    'Imported from sets CSV - Purple Vest Tie Deep Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/vest-tie_deep-purple-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'vest-tie-deep-vest-and-tie-set',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 45: Vest Tie Magenta Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0045',
    'Vest Tie Magenta Vest And Tie Set',
    'Imported from sets CSV - Vest Tie Magenta Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/vest-tie_magenta-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'vest-tie-magenta-vest-and-tie-set',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 46: Brown Vest Tie Medium Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0046',
    'Brown Vest Tie Medium Vest And Tie Set',
    'Imported from sets CSV - Brown Vest Tie Medium Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/vest-tie_medium-brown-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'vest-tie-medium-vest-and-tie-set',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 47: Beige Vest Tie Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0047',
    'Beige Vest Tie Vest And Tie Set',
    'Imported from sets CSV - Beige Vest Tie Vest And Tie Set',
    95,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/vest-tie_charcoal-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'vest-tie-vest-and-tie-set',
        'total_images', 6,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 48: Vest Tie Plum Vest And Tie Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0048',
    'Vest Tie Plum Vest And Tie Set',
    'Imported from sets CSV - Vest Tie Plum Vest And Tie Set',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/vest-tie_plum-vest-and-tie-set_1.0.jpg',
    jsonb_build_object(
        'source', 'sets_csv',
        'original_slug', 'vest-tie-plum-vest-and-tie-set',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 49: Black Boot Jotter Cap Toe
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0049',
    'Black Boot Jotter Cap Toe',
    'Imported from main CSV - Black Boot Jotter Cap Toe',
    89,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/boot_black-jotter-cap-toe_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'boot-jotter-cap-toe',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 50: Navy Boots Chelsea Boots
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0050',
    'Navy Boots Chelsea Boots',
    'Imported from main CSV - Navy Boots Chelsea Boots',
    114,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/boots_beige-chelsea-boots_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'boots-chelsea-boots',
        'total_images', 4,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 51: Red Black Bowtie And With Matching Bowtie
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0051',
    'Red Black Bowtie And With Matching Bowtie',
    'Imported from main CSV - Red Black Bowtie And With Matching Bowtie',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/bowtie_red-and-black-with-matching-bowtie_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'bowtie-and-with-matching-bowtie',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 52: Black Red Bowtie With Design With Matching Bowtie
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0052',
    'Black Red Bowtie With Design With Matching Bowtie',
    'Imported from main CSV - Black Red Bowtie With Design With Matching Bowtie',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/bowtie_black-with-red-design-with-matching-bowtie_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'bowtie-with-design-with-matching-bowtie',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 53: Red Cummerband Cummerbund Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'FOR-CSV-0053',
    'Red Cummerband Cummerbund Set',
    'Imported from main CSV - Red Cummerband Cummerbund Set',
    60,
    'Formal Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/cummerband_royal-blue-cummerbund-set_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'cummerband-cummerbund-set',
        'total_images', 3,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 54: Red Dress Shirt Dress Shirt
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHI-CSV-0054',
    'Red Dress Shirt Dress Shirt',
    'Imported from main CSV - Red Dress Shirt Dress Shirt',
    65,
    'Shirts',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/dress-shirt_white-dress-shirt_1.0.png',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'dress-shirt-dress-shirt',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 55: Black White Gold Dress Shoe And Prom Sneakers With Spikes
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0055',
    'Black White Gold Dress Shoe And Prom Sneakers With Spikes',
    'Imported from main CSV - Black White Gold Dress Shoe And Prom Sneakers With Spikes',
    89,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/dress-shoe_black-and-white-prom-sneakers-with-gold-spikes_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'dress-shoe-and-prom-sneakers-with-spikes',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 56: White Dress Shoe All Leather Versatile Sneakers Prom Professional
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0056',
    'White Dress Shoe All Leather Versatile Sneakers Prom Professional',
    'Imported from main CSV - White Dress Shoe All Leather Versatile Sneakers Prom Professional',
    89,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/dress-shoe_all-white-leather-versatile-sneakers-prom-professional_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'dress-shoe-all-leather-versatile-sneakers-prom-professional',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 57: White Cobalt Blue Dress Shoe Leather Sneakers With Accent Versatile Prom Eleganc
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0057',
    'White Cobalt Blue Dress Shoe Leather Sneakers With Accent Versatile Prom Eleganc',
    'Imported from main CSV - White Cobalt Blue Dress Shoe Leather Sneakers With Accent Versatile Prom Eleganc',
    89,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/dress-shoe_white-leather-sneakers-with-cobalt-blue-accent-versatile-prom-eleganc_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'dress-shoe-leather-sneakers-with-accent-versatile-prom-eleganc',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 58: White Black Dress Shoe Leather Sneakers With Accent Versatile Prom Elegance
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0058',
    'White Black Dress Shoe Leather Sneakers With Accent Versatile Prom Elegance',
    'Imported from main CSV - White Black Dress Shoe Leather Sneakers With Accent Versatile Prom Elegance',
    89,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/dress-shoe_white-leather-sneakers-with-black-accent-versatile-prom-elegance_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'dress-shoe-leather-sneakers-with-accent-versatile-prom-elegance',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 59: Gold Dress Shoe Kct Menswear Studded Sneakers Dazzling Urban Luxury
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0059',
    'Gold Dress Shoe Kct Menswear Studded Sneakers Dazzling Urban Luxury',
    'Imported from main CSV - Gold Dress Shoe Kct Menswear Studded Sneakers Dazzling Urban Luxury',
    89,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/dress-shoe_kct-menswear-gold-studded-sneakers-dazzling-urban-luxury_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'dress-shoe-kct-menswear-studded-sneakers-dazzling-urban-luxury',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 60: Silver Black Silver Dress Shoe Prom Loafers Mens Sparkle Dress
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0060',
    'Silver Black Silver Dress Shoe Prom Loafers Mens Sparkle Dress',
    'Imported from main CSV - Silver Black Silver Dress Shoe Prom Loafers Mens Sparkle Dress',
    89,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/dress-shoe_silver-prom-loafers-mens-black-silver-sparkle-dress_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'dress-shoe-prom-loafers-mens-sparkle-dress',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 61: Black Red Dress Shoe Leather Sneakers With Detail Prom Professional
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0061',
    'Black Red Dress Shoe Leather Sneakers With Detail Prom Professional',
    'Imported from main CSV - Black Red Dress Shoe Leather Sneakers With Detail Prom Professional',
    114,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/dress-shoe_white-leather-sneakers-with-red-detail-prom-professional_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'dress-shoe-leather-sneakers-with-detail-prom-professional',
        'total_images', 3,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 62: Gold Dress Shoe Prom Loafers Mens Sparkle Dress Shoes
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0062',
    'Gold Dress Shoe Prom Loafers Mens Sparkle Dress Shoes',
    'Imported from main CSV - Gold Dress Shoe Prom Loafers Mens Sparkle Dress Shoes',
    89,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/dress-shoe_gold-prom-loafers-mens-sparkle-dress-shoes_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'dress-shoe-prom-loafers-mens-sparkle-dress-shoes',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 63: Black Gold Dress Shoe Rhinestone Prom Loafers
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0063',
    'Black Gold Dress Shoe Rhinestone Prom Loafers',
    'Imported from main CSV - Black Gold Dress Shoe Rhinestone Prom Loafers',
    89,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/dress-shoe_white-gold-rhinestone-prom-loafers_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'dress-shoe-rhinestone-prom-loafers',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 64: Royal Blue Dress Shoe Sparkling Loafers Prom Shoes
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0064',
    'Royal Blue Dress Shoe Sparkling Loafers Prom Shoes',
    'Imported from main CSV - Royal Blue Dress Shoe Sparkling Loafers Prom Shoes',
    114,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/dress-shoe_sparkling-black-loafers-prom-shoes_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'dress-shoe-sparkling-loafers-prom-shoes',
        'total_images', 4,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 65: Silver Dress Shoe Studded Low Top Sneakers Edgy Elegance
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0065',
    'Silver Dress Shoe Studded Low Top Sneakers Edgy Elegance',
    'Imported from main CSV - Silver Dress Shoe Studded Low Top Sneakers Edgy Elegance',
    89,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/dress-shoe_silver-studded-low-top-sneakers-edgy-elegance_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'dress-shoe-studded-low-top-sneakers-edgy-elegance',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 66: Royal Blue Gold Dress Shoe Velvet Loafers Spikes Prom Shoes
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0066',
    'Royal Blue Gold Dress Shoe Velvet Loafers Spikes Prom Shoes',
    'Imported from main CSV - Royal Blue Gold Dress Shoe Velvet Loafers Spikes Prom Shoes',
    139,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/dress-shoe_black-velvet-loafers-gold-spikes-prom-shoes_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'dress-shoe-velvet-loafers-spikes-prom-shoes',
        'total_images', 6,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 67: Rose Dress Shoe Sparkling Dusty Loafers Prom Shoes
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0067',
    'Rose Dress Shoe Sparkling Dusty Loafers Prom Shoes',
    'Imported from main CSV - Rose Dress Shoe Sparkling Dusty Loafers Prom Shoes',
    89,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/dress-shoe_sparkling-dusty-rose-loafers-prom-shoes_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'dress-shoe-sparkling-dusty-loafers-prom-shoes',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 68: Green Dress Shoe Sparkling Emerald Loafers Prom Shoes
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0068',
    'Green Dress Shoe Sparkling Emerald Loafers Prom Shoes',
    'Imported from main CSV - Green Dress Shoe Sparkling Emerald Loafers Prom Shoes',
    89,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/dress-shoe_sparkling-emerald-green-loafers-prom-shoes_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'dress-shoe-sparkling-emerald-loafers-prom-shoes',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 69: Hunter Green Dress Shoe Studded Prom Loafers
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0069',
    'Hunter Green Dress Shoe Studded Prom Loafers',
    'Imported from main CSV - Hunter Green Dress Shoe Studded Prom Loafers',
    89,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/dress-shoe_royal-blue-studded-prom-loafers_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'dress-shoe-studded-prom-loafers',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 70: Royal Blue Dress Shoe Velvet Rhinestone Prom Loafers
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0070',
    'Royal Blue Dress Shoe Velvet Rhinestone Prom Loafers',
    'Imported from main CSV - Royal Blue Dress Shoe Velvet Rhinestone Prom Loafers',
    89,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/dress-shoe_red-velvet-rhinestone-prom-loafers_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'dress-shoe-velvet-rhinestone-prom-loafers',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 71: Red Dress Shoe Velvet Studded Prom Loafers
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0071',
    'Red Dress Shoe Velvet Studded Prom Loafers',
    'Imported from main CSV - Red Dress Shoe Velvet Studded Prom Loafers',
    89,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/dress-shoe_red-velvet-studded-prom-loafers_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'dress-shoe-velvet-studded-prom-loafers',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 72: Black Jacket Puffer Jacket
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'OUT-CSV-0072',
    'Black Jacket Puffer Jacket',
    'Imported from main CSV - Black Jacket Puffer Jacket',
    184,
    'Outerwear',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/jacket_grey-puffer-jacket_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'jacket-puffer-jacket',
        'total_images', 4,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 73: Black Jacket Modern Jacket
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'OUT-CSV-0073',
    'Black Jacket Modern Jacket',
    'Imported from main CSV - Black Jacket Modern Jacket',
    159,
    'Outerwear',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/jacket_black-modern-jacket_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'jacket-modern-jacket',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 74: Camel Jacket Sherpa Puffer
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'OUT-CSV-0074',
    'Camel Jacket Sherpa Puffer',
    'Imported from main CSV - Camel Jacket Sherpa Puffer',
    159,
    'Outerwear',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/jacket_grey-sherpa-puffer_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'jacket-sherpa-puffer',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 75: Royal Blue Kid Suit Kids Suit
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0075',
    'Royal Blue Kid Suit Kids Suit',
    'Imported from main CSV - Royal Blue Kid Suit Kids Suit',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/kid-suit_black-kids-suit_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'kid-suit-kids-suit',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 76: Black Kid Tux Kids Tux
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0076',
    'Black Kid Tux Kids Tux',
    'Imported from main CSV - Black Kid Tux Kids Tux',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/kid-tux_royal-blue-kids-tux_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'kid-tux-kids-tux',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 77: Blue Black Mens Blazers Mens Slim Fit Midnight Tuxedo With Satin Shawl Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0077',
    'Blue Black Mens Blazers Mens Slim Fit Midnight Tuxedo With Satin Shawl Lapel',
    'Imported from main CSV - Blue Black Mens Blazers Mens Slim Fit Midnight Tuxedo With Satin Shawl Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-blazers_mens-slim-fit-midnight-blue-tuxedo-with-black-satin-shawl-lapel_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-blazers-mens-slim-fit-midnight-tuxedo-with-satin-shawl-lapel',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 78: Brown Mens Double Breasted Suit Classic Check Double Breasted Suit The Connoisseurs Choice
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0078',
    'Brown Mens Double Breasted Suit Classic Check Double Breasted Suit The Connoisseurs Choice',
    'Imported from main CSV - Brown Mens Double Breasted Suit Classic Check Double Breasted Suit The Connoisseurs Choice',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/mens-double-breasted-suit_classic-brown-check-double-breasted-suit-the-connoisseurs-choice_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-double-breasted-suit-classic-check-double-breasted-suit-the-connoisseurs-choice',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 79: Navy Blue Mens Blazers Mens Slim Fit Tuxedo With Satin Shawl Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0079',
    'Navy Blue Mens Blazers Mens Slim Fit Tuxedo With Satin Shawl Lapel',
    'Imported from main CSV - Navy Blue Mens Blazers Mens Slim Fit Tuxedo With Satin Shawl Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/mens-blazers_mens-slim-fit-navy-blue-tuxedo-with-satin-shawl-lapel-1_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-blazers-mens-slim-fit-tuxedo-with-satin-shawl-lapel',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 80: Grey Mens Blazers Mens Slim Fit Light Tuxedo With Satin Shawl Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0080',
    'Grey Mens Blazers Mens Slim Fit Light Tuxedo With Satin Shawl Lapel',
    'Imported from main CSV - Grey Mens Blazers Mens Slim Fit Light Tuxedo With Satin Shawl Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-blazers_mens-slim-fit-light-grey-tuxedo-with-satin-shawl-lapel_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-blazers-mens-slim-fit-light-tuxedo-with-satin-shawl-lapel',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 81: Gray Mens Double Breasted Suit Classic Double Breasted Suit Ensemble
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0081',
    'Gray Mens Double Breasted Suit Classic Double Breasted Suit Ensemble',
    'Imported from main CSV - Gray Mens Double Breasted Suit Classic Double Breasted Suit Ensemble',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-double-breasted-suit_classic-gray-double-breasted-suit-ensemble_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-double-breasted-suit-classic-double-breasted-suit-ensemble',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 82: Lavender Mens Double Breasted Suit Dream Double Breasted Suit Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0082',
    'Lavender Mens Double Breasted Suit Dream Double Breasted Suit Set',
    'Imported from main CSV - Lavender Mens Double Breasted Suit Dream Double Breasted Suit Set',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-double-breasted-suit_lavender-dream-double-breasted-suit-set_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-double-breasted-suit-dream-double-breasted-suit-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 83: Pink Mens Double Breasted Suit Pastel Pinstripe Double Breasted Suit Casual Chic
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0083',
    'Pink Mens Double Breasted Suit Pastel Pinstripe Double Breasted Suit Casual Chic',
    'Imported from main CSV - Pink Mens Double Breasted Suit Pastel Pinstripe Double Breasted Suit Casual Chic',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/mens-double-breasted-suit_pastel-pink-pinstripe-double-breasted-suit-casual-chic_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-double-breasted-suit-pastel-pinstripe-double-breasted-suit-casual-chic',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 84: Blue Mens Double Breasted Suit Ocean Textured Double Breasted Suit A Splash OF Style
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0084',
    'Blue Mens Double Breasted Suit Ocean Textured Double Breasted Suit A Splash OF Style',
    'Imported from main CSV - Blue Mens Double Breasted Suit Ocean Textured Double Breasted Suit A Splash OF Style',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-double-breasted-suit_ocean-blue-textured-double-breasted-suit-a-splash-of-style_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-double-breasted-suit-ocean-textured-double-breasted-suit-a-splash-of-style',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 85: Yellow Mens Double Breasted Suit Sunny Elegance Double Breasted Suit
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0085',
    'Yellow Mens Double Breasted Suit Sunny Elegance Double Breasted Suit',
    'Imported from main CSV - Yellow Mens Double Breasted Suit Sunny Elegance Double Breasted Suit',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/mens-double-breasted-suit_sunny-elegance-double-breasted-yellow-suit_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-double-breasted-suit-sunny-elegance-double-breasted-suit',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 86: Navy Blue Mens Double Breasted Suit Pinstripe Double Breasted Suit Executive Precision
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0086',
    'Navy Blue Mens Double Breasted Suit Pinstripe Double Breasted Suit Executive Precision',
    'Imported from main CSV - Navy Blue Mens Double Breasted Suit Pinstripe Double Breasted Suit Executive Precision',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/mens-double-breasted-suit_navy-blue-pinstripe-double-breasted-suit-executive-precision_1.0.png',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-double-breasted-suit-pinstripe-double-breasted-suit-executive-precision',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 87: Mens Double Breasted Suit Sage Elegance Double Breasted Suit Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0087',
    'Mens Double Breasted Suit Sage Elegance Double Breasted Suit Set',
    'Imported from main CSV - Mens Double Breasted Suit Sage Elegance Double Breasted Suit Set',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/mens-double-breasted-suit_sage-elegance-double-breasted-suit-set_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-double-breasted-suit-sage-elegance-double-breasted-suit-set',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 88: White Grey Mens Sweaters And Heavy Sweater
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'KNI-CSV-0088',
    'White Grey Mens Sweaters And Heavy Sweater',
    'Imported from main CSV - White Grey Mens Sweaters And Heavy Sweater',
    79,
    'Knitwear',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-sweaters_white-and-grey-heavy-sweater_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-sweaters-and-heavy-sweater',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 89: Black Mens Tuxedos Mens Classic Three Piece Tuxedo With Satin Shawl Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0089',
    'Black Mens Tuxedos Mens Classic Three Piece Tuxedo With Satin Shawl Lapel',
    'Imported from main CSV - Black Mens Tuxedos Mens Classic Three Piece Tuxedo With Satin Shawl Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-tuxedos_mens-classic-black-three-piece-tuxedo-with-satin-shawl-lapel_1.0.png',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-tuxedos-mens-classic-three-piece-tuxedo-with-satin-shawl-lapel',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 90: Green Black Mens Suits Mens Slim Fit Emerald Tuxedo With Satin Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0090',
    'Green Black Mens Suits Mens Slim Fit Emerald Tuxedo With Satin Lapel',
    'Imported from main CSV - Green Black Mens Suits Mens Slim Fit Emerald Tuxedo With Satin Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-suits_mens-slim-fit-emerald-green-tuxedo-with-black-satin-lapel_1.0.png',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-suits-mens-slim-fit-emerald-tuxedo-with-satin-lapel',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 91: Black White Mens Sweaters Mens Heavyweight Multi Pattern Knit Sweater
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'KNI-CSV-0091',
    'Black White Mens Sweaters Mens Heavyweight Multi Pattern Knit Sweater',
    'Imported from main CSV - Black White Mens Sweaters Mens Heavyweight Multi Pattern Knit Sweater',
    79,
    'Knitwear',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/mens-sweaters_mens-black-white-heavyweight-multi-pattern-knit-sweater_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-sweaters-mens-heavyweight-multi-pattern-knit-sweater',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 92: White Black Mens Tuxedos Mens Slim Fit And Tuxedo With Satin Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0092',
    'White Black Mens Tuxedos Mens Slim Fit And Tuxedo With Satin Lapel',
    'Imported from main CSV - White Black Mens Tuxedos Mens Slim Fit And Tuxedo With Satin Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/mens-tuxedos_mens-slim-fit-white-and-black-tuxedo-with-satin-lapel_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-tuxedos-mens-slim-fit-and-tuxedo-with-satin-lapel',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 93: Grey Mens Suits Mens Slim Fit Tweed Three Piece Suit
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0093',
    'Grey Mens Suits Mens Slim Fit Tweed Three Piece Suit',
    'Imported from main CSV - Grey Mens Suits Mens Slim Fit Tweed Three Piece Suit',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/mens-suits_mens-slim-fit-grey-tweed-three-piece-suit_1.0.png',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-suits-mens-slim-fit-tweed-three-piece-suit',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 94: Black Mens Tuxedos Mens Slim Fit Classic Tuxedo With Satin Notch Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0094',
    'Black Mens Tuxedos Mens Slim Fit Classic Tuxedo With Satin Notch Lapel',
    'Imported from main CSV - Black Mens Tuxedos Mens Slim Fit Classic Tuxedo With Satin Notch Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-tuxedos_mens-slim-fit-classic-black-tuxedo-with-satin-notch-lapel_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-tuxedos-mens-slim-fit-classic-tuxedo-with-satin-notch-lapel',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 95: Black Mens Tuxedos Mens Slim Fit Double Breasted Tuxedo With Satin Peak Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0095',
    'Black Mens Tuxedos Mens Slim Fit Double Breasted Tuxedo With Satin Peak Lapel',
    'Imported from main CSV - Black Mens Tuxedos Mens Slim Fit Double Breasted Tuxedo With Satin Peak Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/mens-tuxedos_mens-slim-fit-white-double-breasted-tuxedo-with-black-satin-peak-lapel_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-tuxedos-mens-slim-fit-double-breasted-tuxedo-with-satin-peak-lapel',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 96: Grey Mens Suits Mens Slim Fit Light Three Piece Suit
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0096',
    'Grey Mens Suits Mens Slim Fit Light Three Piece Suit',
    'Imported from main CSV - Grey Mens Suits Mens Slim Fit Light Three Piece Suit',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-suits_mens-slim-fit-light-grey-three-piece-suit_1.0.png',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-suits-mens-slim-fit-light-three-piece-suit',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 97: Blue Mens Double Breasted Suit Kct Menswear Light Checkered Double Breasted Suit Breezy Elegance
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0097',
    'Blue Mens Double Breasted Suit Kct Menswear Light Checkered Double Breasted Suit Breezy Elegance',
    'Imported from main CSV - Blue Mens Double Breasted Suit Kct Menswear Light Checkered Double Breasted Suit Breezy Elegance',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-double-breasted-suit_kct-menswear-light-blue-checkered-double-breasted-suit-breezy-elegance_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-double-breasted-suit-kct-menswear-light-checkered-double-breasted-suit-breezy-elegance',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 98: Grey Mens Tuxedos Mens Slim Fit Light Tuxedo With Satin Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0098',
    'Grey Mens Tuxedos Mens Slim Fit Light Tuxedo With Satin Lapel',
    'Imported from main CSV - Grey Mens Tuxedos Mens Slim Fit Light Tuxedo With Satin Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-tuxedos_mens-slim-fit-light-grey-tuxedo-with-satin-lapel-1_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-tuxedos-mens-slim-fit-light-tuxedo-with-satin-lapel',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 99: Red Black Mens Tuxedos Mens Slim Fit Double Breasted Tuxedo With Satin Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0099',
    'Red Black Mens Tuxedos Mens Slim Fit Double Breasted Tuxedo With Satin Lapel',
    'Imported from main CSV - Red Black Mens Tuxedos Mens Slim Fit Double Breasted Tuxedo With Satin Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-tuxedos_mens-slim-fit-red-double-breasted-tuxedo-with-black-satin-lapel_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-tuxedos-mens-slim-fit-double-breasted-tuxedo-with-satin-lapel',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 100: Royal Blue Black Mens Tuxedos Mens Slim Fit Tuxedo With Satin Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0100',
    'Royal Blue Black Mens Tuxedos Mens Slim Fit Tuxedo With Satin Lapel',
    'Imported from main CSV - Royal Blue Black Mens Tuxedos Mens Slim Fit Tuxedo With Satin Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/mens-tuxedos_mens-slim-fit-charcoal-grey-tuxedo-with-black-satin-lapel_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-tuxedos-mens-slim-fit-tuxedo-with-satin-lapel',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 101: Burgundy Black Mens Tuxedos Mens Slim Fit Tuxedo Jacket With Satin Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0101',
    'Burgundy Black Mens Tuxedos Mens Slim Fit Tuxedo Jacket With Satin Lapel',
    'Imported from main CSV - Burgundy Black Mens Tuxedos Mens Slim Fit Tuxedo Jacket With Satin Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/mens-tuxedos_mens-slim-fit-burgundy-tuxedo-jacket-with-black-satin-lapel_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-tuxedos-mens-slim-fit-tuxedo-jacket-with-satin-lapel',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 102: Teal Blue Mens Tuxedos Mens Slim Fit Three Piece Tuxedo With Satin Shawl Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0102',
    'Teal Blue Mens Tuxedos Mens Slim Fit Three Piece Tuxedo With Satin Shawl Lapel',
    'Imported from main CSV - Teal Blue Mens Tuxedos Mens Slim Fit Three Piece Tuxedo With Satin Shawl Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/mens-tuxedos_mens-slim-fit-teal-blue-three-piece-tuxedo-with-satin-shawl-lapel_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-tuxedos-mens-slim-fit-three-piece-tuxedo-with-satin-shawl-lapel',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 103: Royal Blue Mens Tuxedos Mens Slim Fit Tuxedo With Satin Lapels
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0103',
    'Royal Blue Mens Tuxedos Mens Slim Fit Tuxedo With Satin Lapels',
    'Imported from main CSV - Royal Blue Mens Tuxedos Mens Slim Fit Tuxedo With Satin Lapels',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/mens-tuxedos_mens-slim-fit-royal-blue-tuxedo-with-satin-lapels_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-tuxedos-mens-slim-fit-tuxedo-with-satin-lapels',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 104: Red Black Mens Tuxedos Mens Slim Fit Tuxedo With Satin Lapel And Matching Vest
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0104',
    'Red Black Mens Tuxedos Mens Slim Fit Tuxedo With Satin Lapel And Matching Vest',
    'Imported from main CSV - Red Black Mens Tuxedos Mens Slim Fit Tuxedo With Satin Lapel And Matching Vest',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/mens-tuxedos_mens-slim-fit-red-tuxedo-with-black-satin-lapel-and-matching-vest_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'mens-tuxedos-mens-slim-fit-tuxedo-with-satin-lapel-and-matching-vest',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 105: Red Black Nan And Heavy Sweater
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'KNI-CSV-0105',
    'Red Black Nan And Heavy Sweater',
    'Imported from main CSV - Red Black Nan And Heavy Sweater',
    79,
    'Knitwear',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_red-and-black-heavy-sweater_6.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-and-heavy-sweater',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 106: White Nan All Suit With Vest
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0106',
    'White Nan All Suit With Vest',
    'Imported from main CSV - White Nan All Suit With Vest',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/nan_all-white-suit-with-vest_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-all-suit-with-vest',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 107: Black White Nan And Tuxedo
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0107',
    'Black White Nan And Tuxedo',
    'Imported from main CSV - Black White Nan And Tuxedo',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_black-and-white-tuxedo_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-and-tuxedo',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 108: Nan Burgund Sparkle Vest And Bowtie
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0108',
    'Nan Burgund Sparkle Vest And Bowtie',
    'Imported from main CSV - Nan Burgund Sparkle Vest And Bowtie',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_burgund-sparkle-vest-and-bowtie_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-burgund-sparkle-vest-and-bowtie',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 109: Silver Black Nan Dazzling Shiny Tuxedo With Paisley Design A Showstopper Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0109',
    'Silver Black Nan Dazzling Shiny Tuxedo With Paisley Design A Showstopper Prom And Wedding Seasons',
    'Imported from main CSV - Silver Black Nan Dazzling Shiny Tuxedo With Paisley Design A Showstopper Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/nan_dazzling-shiny-silver-tuxedo-with-black-paisley-design-a-showstopper-prom-and-wedding-seasons_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-dazzling-shiny-tuxedo-with-paisley-design-a-showstopper-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 110: Black Nan Double Breasted Prom Tuxedo Satin Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0110',
    'Black Nan Double Breasted Prom Tuxedo Satin Lapel',
    'Imported from main CSV - Black Nan Double Breasted Prom Tuxedo Satin Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_black-double-breasted-prom-tuxedo-satin-lapel_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-double-breasted-prom-tuxedo-satin-lapel',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 111: Ivory Nan Double Breasted Suit Classic Summer Luxury
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0111',
    'Ivory Nan Double Breasted Suit Classic Summer Luxury',
    'Imported from main CSV - Ivory Nan Double Breasted Suit Classic Summer Luxury',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_ivory-double-breasted-suit-classic-summer-luxury_2.0.png',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-double-breasted-suit-classic-summer-luxury',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 112: White Black Nan Double Breasted Tuxedo
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0112',
    'White Black Nan Double Breasted Tuxedo',
    'Imported from main CSV - White Black Nan Double Breasted Tuxedo',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/nan_white-black-double-breasted-tuxedo_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-double-breasted-tuxedo',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 113: Black Nan Dress Boot
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0113',
    'Black Nan Dress Boot',
    'Imported from main CSV - Black Nan Dress Boot',
    89,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_black-dress-boot_6.0.webp',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-dress-boot',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 114: Blue Nan Dusty Three Piece Suit Timeless Elegance For
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0114',
    'Blue Nan Dusty Three Piece Suit Timeless Elegance For',
    'Imported from main CSV - Blue Nan Dusty Three Piece Suit Timeless Elegance For',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_dusty-blue-three-piece-suit-timeless-elegance-for-2025_3.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-dusty-three-piece-suit-timeless-elegance-for',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 115: Black Nan Elegant Paisley Three Piece Tuxedo With Velvet Lapel A Modern Classic For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0115',
    'Black Nan Elegant Paisley Three Piece Tuxedo With Velvet Lapel A Modern Classic For Prom And Wedding Seasons',
    'Imported from main CSV - Black Nan Elegant Paisley Three Piece Tuxedo With Velvet Lapel A Modern Classic For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_elegant-black-paisley-three-piece-tuxedo-with-velvet-lapel-a-modern-classic-for-2024-prom-and-wedding-seasons_2.0.webp',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-elegant-paisley-three-piece-tuxedo-with-velvet-lapel-a-modern-classic-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 116: Black Nan Elegant All Satin Paisley Suit A Sophisticated Choice For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0116',
    'Black Nan Elegant All Satin Paisley Suit A Sophisticated Choice For Prom And Wedding Seasons',
    'Imported from main CSV - Black Nan Elegant All Satin Paisley Suit A Sophisticated Choice For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/nan_elegant-all-black-satin-paisley-suit-a-sophisticated-choice-for-prom-and-wedding-seasons_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-elegant-all-satin-paisley-suit-a-sophisticated-choice-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 117: White Nan European Prom Tuxedo Shawl Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0117',
    'White Nan European Prom Tuxedo Shawl Lapel',
    'Imported from main CSV - White Nan European Prom Tuxedo Shawl Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_white-european-prom-tuxedo-2025-shawl-lapel_8.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-european-prom-tuxedo-shawl-lapel',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 118: Cream Nan Elegant Double Breasted Suit Summer Sophistication
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0118',
    'Cream Nan Elegant Double Breasted Suit Summer Sophistication',
    'Imported from main CSV - Cream Nan Elegant Double Breasted Suit Summer Sophistication',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_elegant-cream-double-breasted-suit-summer-sophistication_2.0.png',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-elegant-double-breasted-suit-summer-sophistication',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 119: White Nan Elegant Design Three Piece Tuxedo With Satin Lapel A Sophisticated Choice For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0119',
    'White Nan Elegant Design Three Piece Tuxedo With Satin Lapel A Sophisticated Choice For Prom And Wedding Seasons',
    'Imported from main CSV - White Nan Elegant Design Three Piece Tuxedo With Satin Lapel A Sophisticated Choice For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_elegant-white-design-three-piece-tuxedo-with-satin-lapel-a-sophisticated-choice-for-2024-prom-and-wedding-seasons_2.0.webp',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-elegant-design-three-piece-tuxedo-with-satin-lapel-a-sophisticated-choice-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 120: Burgundy Nan European Prom Tuxedo Velvet Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0120',
    'Burgundy Nan European Prom Tuxedo Velvet Lapel',
    'Imported from main CSV - Burgundy Nan European Prom Tuxedo Velvet Lapel',
    324,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_green-european-prom-tuxedo-2025-velvet-lapel_8.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-european-prom-tuxedo-velvet-lapel',
        'total_images', 4,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 121: Hunter Green Black Nan Exquisite And Paisley Three Piece Tuxedo With Velvet Lapel A Luxurious Choice For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0121',
    'Hunter Green Black Nan Exquisite And Paisley Three Piece Tuxedo With Velvet Lapel A Luxurious Choice For Prom And Wedding Seasons',
    'Imported from main CSV - Hunter Green Black Nan Exquisite And Paisley Three Piece Tuxedo With Velvet Lapel A Luxurious Choice For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_exquisite-hunter-green-and-black-paisley-three-piece-tuxedo-with-velvet-lapel-a-luxurious-choice-for-2024-prom-and-wedding-seasons_3.0.webp',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-exquisite-and-paisley-three-piece-tuxedo-with-velvet-lapel-a-luxurious-choice-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 122: Black Nan Fall Suit
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0122',
    'Black Nan Fall Suit',
    'Imported from main CSV - Black Nan Fall Suit',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/nan_black-fall-suit_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-fall-suit',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 123: Nan Kct Menswear Gift Card
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0123',
    'Nan Kct Menswear Gift Card',
    'Imported from main CSV - Nan Kct Menswear Gift Card',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_kct-menswear-gift-card_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-kct-menswear-gift-card',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 124: Tan Nan Kct Menswear Glen Plaid Double Breasted Suit Summer Sophistication
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0124',
    'Tan Nan Kct Menswear Glen Plaid Double Breasted Suit Summer Sophistication',
    'Imported from main CSV - Tan Nan Kct Menswear Glen Plaid Double Breasted Suit Summer Sophistication',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_kct-menswear-tan-glen-plaid-double-breasted-suit-summer-sophistication_3.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-kct-menswear-glen-plaid-double-breasted-suit-summer-sophistication',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 125: Nan Light Blush Tuxedo With Matching Bowtie
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0125',
    'Nan Light Blush Tuxedo With Matching Bowtie',
    'Imported from main CSV - Nan Light Blush Tuxedo With Matching Bowtie',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_03/nan_light-blush-tuxedo-with-matching-bowtie_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-light-blush-tuxedo-with-matching-bowtie',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 126: Blue Nan Light Double Breasted Slim Stretch Suit
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0126',
    'Blue Nan Light Double Breasted Slim Stretch Suit',
    'Imported from main CSV - Blue Nan Light Double Breasted Slim Stretch Suit',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_light-blue-double-breasted-slim-stretch-suit-2025_3.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-light-double-breasted-slim-stretch-suit',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 127: Blue Nan Light Stretch Suit Sleek Modern Piece For
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0127',
    'Blue Nan Light Stretch Suit Sleek Modern Piece For',
    'Imported from main CSV - Blue Nan Light Stretch Suit Sleek Modern Piece For',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_light-blue-stretch-suit-sleek-modern-2-piece-for-2025_3.0.webp',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-light-stretch-suit-sleek-modern-piece-for',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 128: Blue Nan Light Slim Fit Stretch Suit Piece
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0128',
    'Blue Nan Light Slim Fit Stretch Suit Piece',
    'Imported from main CSV - Blue Nan Light Slim Fit Stretch Suit Piece',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_light-blue-slim-fit-stretch-suit-2-piece-2025_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-light-slim-fit-stretch-suit-piece',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 129: Gold Nan Light Tuxedo With Matching Bowtie
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0129',
    'Gold Nan Light Tuxedo With Matching Bowtie',
    'Imported from main CSV - Gold Nan Light Tuxedo With Matching Bowtie',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/nan_light-orange-tuxedo-with-matching-bowtie_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-light-tuxedo-with-matching-bowtie',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 130: Blue Nan Light Three Piece Suit Modern Elegance For
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0130',
    'Blue Nan Light Three Piece Suit Modern Elegance For',
    'Imported from main CSV - Blue Nan Light Three Piece Suit Modern Elegance For',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_light-blue-three-piece-suit-modern-elegance-for-2025_3.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-light-three-piece-suit-modern-elegance-for',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 131: Blue Nan Light Three Piece Slim Fit Suit
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0131',
    'Blue Nan Light Three Piece Slim Fit Suit',
    'Imported from main CSV - Blue Nan Light Three Piece Slim Fit Suit',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_light-blue-three-piece-slim-fit-suit-2025_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-light-three-piece-slim-fit-suit',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 132: Black Nan Long Coat
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0132',
    'Black Nan Long Coat',
    'Imported from main CSV - Black Nan Long Coat',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_black-long-coat_5.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-long-coat',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 133: Hunter Green Black Nan Luxurious And Paisley Three Piece Tuxedo With Satin Lapel A Distinguished Pick For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0133',
    'Hunter Green Black Nan Luxurious And Paisley Three Piece Tuxedo With Satin Lapel A Distinguished Pick For Prom And Wedding Seasons',
    'Imported from main CSV - Hunter Green Black Nan Luxurious And Paisley Three Piece Tuxedo With Satin Lapel A Distinguished Pick For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_luxurious-hunter-green-and-black-paisley-three-piece-tuxedo-with-satin-lapel-a-distinguished-pick-for-2024-prom-and-wedding-seasons_3.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-luxurious-and-paisley-three-piece-tuxedo-with-satin-lapel-a-distinguished-pick-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 134: Burgundy Nan Men S Sequin Lapel Three Piece Prom Tuxedo Bold Elegance Meets Modern Glamour
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0134',
    'Burgundy Nan Men S Sequin Lapel Three Piece Prom Tuxedo Bold Elegance Meets Modern Glamour',
    'Imported from main CSV - Burgundy Nan Men S Sequin Lapel Three Piece Prom Tuxedo Bold Elegance Meets Modern Glamour',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_men-s-burgundy-sequin-lapel-three-piece-prom-tuxedo-bold-elegance-meets-modern-glamour_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-men-s-sequin-lapel-three-piece-prom-tuxedo-bold-elegance-meets-modern-glamour',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 135: Nan Men S Sequin Lapel Three Piece Prom Tuxedo Perfect For Prom
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0135',
    'Nan Men S Sequin Lapel Three Piece Prom Tuxedo Perfect For Prom',
    'Imported from main CSV - Nan Men S Sequin Lapel Three Piece Prom Tuxedo Perfect For Prom',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/nan_men-s-sequin-lapel-three-piece-prom-tuxedo-perfect-for-prom-2025_20.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-men-s-sequin-lapel-three-piece-prom-tuxedo-perfect-for-prom',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 136: White Nan Mens Classic Two Piece Tuxedo With Satin Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0136',
    'White Nan Mens Classic Two Piece Tuxedo With Satin Lapel',
    'Imported from main CSV - White Nan Mens Classic Two Piece Tuxedo With Satin Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_mens-classic-white-two-piece-tuxedo-with-satin-lapel_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-classic-two-piece-tuxedo-with-satin-lapel',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 137: Grey Nan Mens Double Breasted Light Suit Modern Slim Fit
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0137',
    'Grey Nan Mens Double Breasted Light Suit Modern Slim Fit',
    'Imported from main CSV - Grey Nan Mens Double Breasted Light Suit Modern Slim Fit',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_mens-double-breasted-light-grey-suit-modern-slim-fit_3.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-double-breasted-light-suit-modern-slim-fit',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 138: Black Nan Mens Classic Tuxedo With Satin Shawl Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0138',
    'Black Nan Mens Classic Tuxedo With Satin Shawl Lapel',
    'Imported from main CSV - Black Nan Mens Classic Tuxedo With Satin Shawl Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_mens-classic-black-tuxedo-with-satin-shawl-lapel_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-classic-tuxedo-with-satin-shawl-lapel',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 139: Ivory White Nan Mens Double Breasted Suit Modern Slim Fit
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0139',
    'Ivory White Nan Mens Double Breasted Suit Modern Slim Fit',
    'Imported from main CSV - Ivory White Nan Mens Double Breasted Suit Modern Slim Fit',
    324,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_mens-double-breasted-royal-blue-suit-modern-slim-fit_5.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-double-breasted-suit-modern-slim-fit',
        'total_images', 3,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 140: Black Nan Mens Classic Slim Fit Three Piece Tuxedo With Satin Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0140',
    'Black Nan Mens Classic Slim Fit Three Piece Tuxedo With Satin Lapel',
    'Imported from main CSV - Black Nan Mens Classic Slim Fit Three Piece Tuxedo With Satin Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/nan_mens-classic-slim-fit-black-three-piece-tuxedo-with-satin-lapel_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-classic-slim-fit-three-piece-tuxedo-with-satin-lapel',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 141: Black Nan Mens Double Breasted Tuxedo With Satin Shawl Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0141',
    'Black Nan Mens Double Breasted Tuxedo With Satin Shawl Lapel',
    'Imported from main CSV - Black Nan Mens Double Breasted Tuxedo With Satin Shawl Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/nan_mens-double-breasted-black-tuxedo-with-satin-shawl-lapel_3.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-double-breasted-tuxedo-with-satin-shawl-lapel',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 142: Rose Nan Mens Dusty Tuxedo Slim Fit Satin Lapel Suit
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0142',
    'Rose Nan Mens Dusty Tuxedo Slim Fit Satin Lapel Suit',
    'Imported from main CSV - Rose Nan Mens Dusty Tuxedo Slim Fit Satin Lapel Suit',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_mens-dusty-rose-tuxedo-slim-fit-satin-lapel-suit_3.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-dusty-tuxedo-slim-fit-satin-lapel-suit',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 143: Pink Nan Mens Light Paisley Tuxedo Slim Fit Piece Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0143',
    'Pink Nan Mens Light Paisley Tuxedo Slim Fit Piece Set',
    'Imported from main CSV - Pink Nan Mens Light Paisley Tuxedo Slim Fit Piece Set',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/nan_mens-light-blue-paisley-tuxedo-slim-fit-3-piece-set_3.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-light-paisley-tuxedo-slim-fit-piece-set',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 144: White Nan Mens Paisley Tuxedo Slim Fit Piece Set
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0144',
    'White Nan Mens Paisley Tuxedo Slim Fit Piece Set',
    'Imported from main CSV - White Nan Mens Paisley Tuxedo Slim Fit Piece Set',
    324,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_mens-black-paisley-tuxedo-slim-fit-3-piece-set_4.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-paisley-tuxedo-slim-fit-piece-set',
        'total_images', 4,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 145: Gold Nan Mens Light Tuxedo Slim Fit Satin Lapel Suit
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0145',
    'Gold Nan Mens Light Tuxedo Slim Fit Satin Lapel Suit',
    'Imported from main CSV - Gold Nan Mens Light Tuxedo Slim Fit Satin Lapel Suit',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_mens-light-gold-tuxedo-slim-fit-satin-lapel-suit_3.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-light-tuxedo-slim-fit-satin-lapel-suit',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 146: Red Nan Mens Slim Fit Bold Three Piece Suit
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0146',
    'Red Nan Mens Slim Fit Bold Three Piece Suit',
    'Imported from main CSV - Red Nan Mens Slim Fit Bold Three Piece Suit',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_mens-slim-fit-bold-red-three-piece-suit_3.0.png',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-slim-fit-bold-three-piece-suit',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 147: Green Nan Mens Slim Fit Emerald Tuxedo With Satin Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0147',
    'Green Nan Mens Slim Fit Emerald Tuxedo With Satin Lapel',
    'Imported from main CSV - Green Nan Mens Slim Fit Emerald Tuxedo With Satin Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_mens-slim-fit-emerald-green-tuxedo-with-satin-lapel_3.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-slim-fit-emerald-tuxedo-with-satin-lapel',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 148: Grey Nan Mens Slim Fit Light Tuxedo With Satin Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0148',
    'Grey Nan Mens Slim Fit Light Tuxedo With Satin Lapel',
    'Imported from main CSV - Grey Nan Mens Slim Fit Light Tuxedo With Satin Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/nan_mens-slim-fit-light-grey-tuxedo-with-satin-lapel_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-slim-fit-light-tuxedo-with-satin-lapel',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 149: Ivory White Nan Mens Slim Fit Three Piece Suit
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0149',
    'Ivory White Nan Mens Slim Fit Three Piece Suit',
    'Imported from main CSV - Ivory White Nan Mens Slim Fit Three Piece Suit',
    324,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_mens-slim-fit-black-three-piece-suit_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-slim-fit-three-piece-suit',
        'total_images', 5,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 150: Navy Blue Black Nan Mens Slim Fit Tuxedo With Satin Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0150',
    'Navy Blue Black Nan Mens Slim Fit Tuxedo With Satin Lapel',
    'Imported from main CSV - Navy Blue Black Nan Mens Slim Fit Tuxedo With Satin Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/nan_mens-slim-fit-navy-blue-tuxedo-with-black-satin-lapel_3.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-slim-fit-tuxedo-with-satin-lapel',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 151: Royal Blue Nan Mens Slim Fit Tuxedo With Satin Shawl Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0151',
    'Royal Blue Nan Mens Slim Fit Tuxedo With Satin Shawl Lapel',
    'Imported from main CSV - Royal Blue Nan Mens Slim Fit Tuxedo With Satin Shawl Lapel',
    324,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_mens-slim-fit-black-tuxedo-with-satin-shawl-lapel_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-slim-fit-tuxedo-with-satin-shawl-lapel',
        'total_images', 5,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 152: White Nan Mens Slim Fit Two Piece Suit Modern Formalwear
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0152',
    'White Nan Mens Slim Fit Two Piece Suit Modern Formalwear',
    'Imported from main CSV - White Nan Mens Slim Fit Two Piece Suit Modern Formalwear',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_mens-slim-fit-white-two-piece-suit-modern-formalwear_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-slim-fit-two-piece-suit-modern-formalwear',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 153: Brown Nan Mens Slim Fit Tweed Three Piece Suit
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0153',
    'Brown Nan Mens Slim Fit Tweed Three Piece Suit',
    'Imported from main CSV - Brown Nan Mens Slim Fit Tweed Three Piece Suit',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_mens-slim-fit-brown-tweed-three-piece-suit_3.0.png',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-slim-fit-tweed-three-piece-suit',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 154: Royal Blue Nan Mens Slim Fit Two Piece Suit With Vest
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0154',
    'Royal Blue Nan Mens Slim Fit Two Piece Suit With Vest',
    'Imported from main CSV - Royal Blue Nan Mens Slim Fit Two Piece Suit With Vest',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_mens-slim-fit-royal-blue-two-piece-suit-with-vest_3.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-slim-fit-two-piece-suit-with-vest',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 155: Grey Nan Mens Slim Fit Two Tone Tuxedo With Satin Lapel
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0155',
    'Grey Nan Mens Slim Fit Two Tone Tuxedo With Satin Lapel',
    'Imported from main CSV - Grey Nan Mens Slim Fit Two Tone Tuxedo With Satin Lapel',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_mens-slim-fit-two-tone-grey-tuxedo-with-satin-lapel_3.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-slim-fit-two-tone-tuxedo-with-satin-lapel',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 156: Teal Nan Mens Tuxedo Slim Fit Satin Lapel Suit
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0156',
    'Teal Nan Mens Tuxedo Slim Fit Satin Lapel Suit',
    'Imported from main CSV - Teal Nan Mens Tuxedo Slim Fit Satin Lapel Suit',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_mens-champagne-tuxedo-slim-fit-satin-lapel-suit_3.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-tuxedo-slim-fit-satin-lapel-suit',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 157: White Black Nan Mens Tuxedo With Shawl Lapel Three Piece Formal Suit
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0157',
    'White Black Nan Mens Tuxedo With Shawl Lapel Three Piece Formal Suit',
    'Imported from main CSV - White Black Nan Mens Tuxedo With Shawl Lapel Three Piece Formal Suit',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_mens-white-tuxedo-with-black-shawl-lapel-three-piece-formal-suit_2.0.png',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-mens-tuxedo-with-shawl-lapel-three-piece-formal-suit',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 158: White Nan OF Turtleneck
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'KNI-CSV-0158',
    'White Nan OF Turtleneck',
    'Imported from main CSV - White Nan OF Turtleneck',
    79,
    'Knitwear',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/nan_copy-of-white-turtleneck_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-of-turtleneck',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 159: Black Nan OF Slim Suit Three Piece
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0159',
    'Black Nan OF Slim Suit Three Piece',
    'Imported from main CSV - Black Nan OF Slim Suit Three Piece',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_copy-of-slim-black-suit-three-piece_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-of-slim-suit-three-piece',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 160: Black Nan OF Slim Tuxedo
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0160',
    'Black Nan OF Slim Tuxedo',
    'Imported from main CSV - Black Nan OF Slim Tuxedo',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_copy-of-slim-black-tuxedo_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-of-slim-tuxedo',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 161: Black Nan Patent Leather Velvet Loafers The Ultimate Formal Shoe For
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0161',
    'Black Nan Patent Leather Velvet Loafers The Ultimate Formal Shoe For',
    'Imported from main CSV - Black Nan Patent Leather Velvet Loafers The Ultimate Formal Shoe For',
    89,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_black-patent-leather-velvet-loafers-the-ultimate-formal-shoe-for-2025_4.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-patent-leather-velvet-loafers-the-ultimate-formal-shoe-for',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 162: Burgundy Nan Premium Pinstripe Double Breasted Suit Tailored Elegance
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0162',
    'Burgundy Nan Premium Pinstripe Double Breasted Suit Tailored Elegance',
    'Imported from main CSV - Burgundy Nan Premium Pinstripe Double Breasted Suit Tailored Elegance',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/nan_premium-burgundy-pinstripe-double-breasted-suit-tailored-elegance_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-premium-pinstripe-double-breasted-suit-tailored-elegance',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 163: Ivory Gold Nan Refined And Circle Tuxedo A Trendy Selection For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0163',
    'Ivory Gold Nan Refined And Circle Tuxedo A Trendy Selection For Prom And Wedding Seasons',
    'Imported from main CSV - Ivory Gold Nan Refined And Circle Tuxedo A Trendy Selection For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_refined-ivory-and-gold-circle-tuxedo-a-trendy-selection-for-2024-prom-and-wedding-seasons_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-refined-and-circle-tuxedo-a-trendy-selection-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 164: Gold Pink Nan Radiant And Design Tuxedo A Perfect And Elegant Choice For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0164',
    'Gold Pink Nan Radiant And Design Tuxedo A Perfect And Elegant Choice For Prom And Wedding Seasons',
    'Imported from main CSV - Gold Pink Nan Radiant And Design Tuxedo A Perfect And Elegant Choice For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_radiant-gold-and-pink-design-tuxedo-a-perfect-and-elegant-choice-for-prom-and-wedding-seasons_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-radiant-and-design-tuxedo-a-perfect-and-elegant-choice-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 165: Mint Nan Refreshing Design Three Piece Tuxedo With Satin Lapel A Stylish Statement For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0165',
    'Mint Nan Refreshing Design Three Piece Tuxedo With Satin Lapel A Stylish Statement For Prom And Wedding Seasons',
    'Imported from main CSV - Mint Nan Refreshing Design Three Piece Tuxedo With Satin Lapel A Stylish Statement For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_refreshing-mint-design-three-piece-tuxedo-with-satin-lapel-a-stylish-statement-for-2024-prom-and-wedding-seasons_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-refreshing-design-three-piece-tuxedo-with-satin-lapel-a-stylish-statement-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 166: Ivory Gold Nan Regal And Paisley Tuxedo A Luxurious Choice For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0166',
    'Ivory Gold Nan Regal And Paisley Tuxedo A Luxurious Choice For Prom And Wedding Seasons',
    'Imported from main CSV - Ivory Gold Nan Regal And Paisley Tuxedo A Luxurious Choice For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_regal-ivory-and-gold-paisley-tuxedo-a-luxurious-choice-for-prom-and-wedding-seasons_3.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-regal-and-paisley-tuxedo-a-luxurious-choice-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 167: Red Gold Nan Ruby Velvet With Details
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0167',
    'Red Gold Nan Ruby Velvet With Details',
    'Imported from main CSV - Red Gold Nan Ruby Velvet With Details',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_ruby-red-velvet-with-gold-details_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-ruby-velvet-with-details',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 168: Nan Sand Tuxedo Suit BY Kct Menswear A Portrait OF Classic Elegancee Piece Tuxedo A Striking Choice For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0168',
    'Nan Sand Tuxedo Suit BY Kct Menswear A Portrait OF Classic Elegancee Piece Tuxedo A Striking Choice For Prom And Wedding Seasons',
    'Imported from main CSV - Nan Sand Tuxedo Suit BY Kct Menswear A Portrait OF Classic Elegancee Piece Tuxedo A Striking Choice For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_sand-tuxedo-suit-by-kct-menswear-a-portrait-of-classic-elegancee-piece-tuxedo-a-striking-choice-for-2024-prom-and-wedding-seasons_2.0.webp',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-sand-tuxedo-suit-by-kct-menswear-a-portrait-of-classic-elegancee-piece-tuxedo-a-striking-choice-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 169: Gold Nan Sequin Lapel Three Piece Prom Tuxedo
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0169',
    'Gold Nan Sequin Lapel Three Piece Prom Tuxedo',
    'Imported from main CSV - Gold Nan Sequin Lapel Three Piece Prom Tuxedo',
    324,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_black-sequin-lapel-three-piece-prom-tuxedo_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-sequin-lapel-three-piece-prom-tuxedo',
        'total_images', 5,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 170: Rose Gold Nan Sequin Lapel Three Piece Prom Tuxedo Sophisticated Glamour Meets Modern Elegance
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0170',
    'Rose Gold Nan Sequin Lapel Three Piece Prom Tuxedo Sophisticated Glamour Meets Modern Elegance',
    'Imported from main CSV - Rose Gold Nan Sequin Lapel Three Piece Prom Tuxedo Sophisticated Glamour Meets Modern Elegance',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_rose-gold-sequin-lapel-three-piece-prom-tuxedo-sophisticated-glamour-meets-modern-elegance_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-sequin-lapel-three-piece-prom-tuxedo-sophisticated-glamour-meets-modern-elegance',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 171: Tan Nan Sherpa Max Ultimate Cozy Jacket
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'OUT-CSV-0171',
    'Tan Nan Sherpa Max Ultimate Cozy Jacket',
    'Imported from main CSV - Tan Nan Sherpa Max Ultimate Cozy Jacket',
    184,
    'Outerwear',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_sherpa-max-ultimate-cozy-jacket_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-sherpa-max-ultimate-cozy-jacket',
        'total_images', 3,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 172: White Nan Sequin Lapel Three Piece Prom Tuxedo Timeless Elegance With A Modern Twist
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0172',
    'White Nan Sequin Lapel Three Piece Prom Tuxedo Timeless Elegance With A Modern Twist',
    'Imported from main CSV - White Nan Sequin Lapel Three Piece Prom Tuxedo Timeless Elegance With A Modern Twist',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_white-sequin-lapel-three-piece-prom-tuxedo-timeless-elegance-with-a-modern-twist_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-sequin-lapel-three-piece-prom-tuxedo-timeless-elegance-with-a-modern-twist',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 173: Black Nan Sherpa Puffer
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'OUT-CSV-0173',
    'Black Nan Sherpa Puffer',
    'Imported from main CSV - Black Nan Sherpa Puffer',
    159,
    'Outerwear',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_black-sherpa-puffer_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-sherpa-puffer',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 174: Blue Nan Sly Tuxedo With Matching Bowtie
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0174',
    'Blue Nan Sly Tuxedo With Matching Bowtie',
    'Imported from main CSV - Blue Nan Sly Tuxedo With Matching Bowtie',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/nan_sly-blue-tuxedo-with-matching-bowtie_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-sly-tuxedo-with-matching-bowtie',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 175: Blue Nan Slate Trimmed Tuxedo Modern Elegance For
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0175',
    'Blue Nan Slate Trimmed Tuxedo Modern Elegance For',
    'Imported from main CSV - Blue Nan Slate Trimmed Tuxedo Modern Elegance For',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_slate-blue-trimmed-tuxedo-modern-elegance-for-2025_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-slate-trimmed-tuxedo-modern-elegance-for',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 176: White Black Nan Sleek Three Piece Tuxedo With Velvet Lapel A Chic Choice For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0176',
    'White Black Nan Sleek Three Piece Tuxedo With Velvet Lapel A Chic Choice For Prom And Wedding Seasons',
    'Imported from main CSV - White Black Nan Sleek Three Piece Tuxedo With Velvet Lapel A Chic Choice For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/nan_sleek-white-three-piece-tuxedo-with-black-velvet-lapel-a-chic-choice-for-2024-prom-and-wedding-seasons_3.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-sleek-three-piece-tuxedo-with-velvet-lapel-a-chic-choice-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 177: Green Nan Sophisticated Emerald Three Piece Suit With Velvet Lapel A Distinguished Choice For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0177',
    'Green Nan Sophisticated Emerald Three Piece Suit With Velvet Lapel A Distinguished Choice For Prom And Wedding Seasons',
    'Imported from main CSV - Green Nan Sophisticated Emerald Three Piece Suit With Velvet Lapel A Distinguished Choice For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_sophisticated-emerald-green-three-piece-suit-with-velvet-lapel-a-distinguished-choice-for-2024-prom-and-wedding-seasons_3.0.webp',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-sophisticated-emerald-three-piece-suit-with-velvet-lapel-a-distinguished-choice-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 178: Black Nan Sophisticated Paisley Tuxedo With Satin Accents Ideal For Prom Wedding Elegance
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0178',
    'Black Nan Sophisticated Paisley Tuxedo With Satin Accents Ideal For Prom Wedding Elegance',
    'Imported from main CSV - Black Nan Sophisticated Paisley Tuxedo With Satin Accents Ideal For Prom Wedding Elegance',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_sophisticated-black-paisley-tuxedo-with-satin-accents-ideal-for-prom-wedding-elegance_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-sophisticated-paisley-tuxedo-with-satin-accents-ideal-for-prom-wedding-elegance',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 179: Navy Nan Sophisticated Three Piece Tuxedo With Velvet Lapel A Classy Selection For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0179',
    'Navy Nan Sophisticated Three Piece Tuxedo With Velvet Lapel A Classy Selection For Prom And Wedding Seasons',
    'Imported from main CSV - Navy Nan Sophisticated Three Piece Tuxedo With Velvet Lapel A Classy Selection For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_sophisticated-navy-three-piece-tuxedo-with-velvet-lapel-a-classy-selection-for-2024-prom-and-wedding-seasons_3.0.webp',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-sophisticated-three-piece-tuxedo-with-velvet-lapel-a-classy-selection-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 180: Black Nan Sophisticated Jet Flower Tuxedo A Timeless Choice For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0180',
    'Black Nan Sophisticated Jet Flower Tuxedo A Timeless Choice For Prom And Wedding Seasons',
    'Imported from main CSV - Black Nan Sophisticated Jet Flower Tuxedo A Timeless Choice For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_sophisticated-jet-black-flower-tuxedo-a-timeless-choice-for-prom-and-wedding-seasons_3.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-sophisticated-jet-flower-tuxedo-a-timeless-choice-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 181: Silver Nan Sparkle Vest And Bowtie
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0181',
    'Silver Nan Sparkle Vest And Bowtie',
    'Imported from main CSV - Silver Nan Sparkle Vest And Bowtie',
    95,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_royal-blue-sparkle-vest-and-bowtie_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-sparkle-vest-and-bowtie',
        'total_images', 9,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 182: Black Nan Stretch Suit Travelers Suit
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0182',
    'Black Nan Stretch Suit Travelers Suit',
    'Imported from main CSV - Black Nan Stretch Suit Travelers Suit',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/nan_royal-blue-stretch-suit-travelers-suit_3.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-stretch-suit-travelers-suit',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 183: Silver Blue Nan Stunning Sparkle And Design Three Piece Tuxedo A Mesmerizing Choice For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0183',
    'Silver Blue Nan Stunning Sparkle And Design Three Piece Tuxedo A Mesmerizing Choice For Prom And Wedding Seasons',
    'Imported from main CSV - Silver Blue Nan Stunning Sparkle And Design Three Piece Tuxedo A Mesmerizing Choice For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_stunning-sparkle-silver-and-blue-design-three-piece-tuxedo-a-mesmerizing-choice-for-2024-prom-and-wedding-seasons_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-stunning-sparkle-and-design-three-piece-tuxedo-a-mesmerizing-choice-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 184: Yellow Gold Nan Stunning Golden Tuxedo With Trim A Glamorous Choice For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0184',
    'Yellow Gold Nan Stunning Golden Tuxedo With Trim A Glamorous Choice For Prom And Wedding Seasons',
    'Imported from main CSV - Yellow Gold Nan Stunning Golden Tuxedo With Trim A Glamorous Choice For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/nan_stunning-golden-yellow-tuxedo-with-gold-trim-a-glamorous-choice-for-prom-and-wedding-seasons_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-stunning-golden-tuxedo-with-trim-a-glamorous-choice-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 185: Red Nan Suit With Vest
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0185',
    'Red Nan Suit With Vest',
    'Imported from main CSV - Red Nan Suit With Vest',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/nan_black-suit-with-vest_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-suit-with-vest',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 186: Black Nan Three Piece Tux
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0186',
    'Black Nan Three Piece Tux',
    'Imported from main CSV - Black Nan Three Piece Tux',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/nan_black-three-piece-tux_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-three-piece-tux',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 187: Black Nan Three Piece Wedding Tux
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0187',
    'Black Nan Three Piece Wedding Tux',
    'Imported from main CSV - Black Nan Three Piece Wedding Tux',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/nan_black-three-piece-wedding-tux_3.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-three-piece-wedding-tux',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 188: Nan Velvet Prom Loafers
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHO-CSV-0188',
    'Nan Velvet Prom Loafers',
    'Imported from main CSV - Nan Velvet Prom Loafers',
    89,
    'Shoes',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_velvet-prom-loafers-2025_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-velvet-prom-loafers',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 189: Rose Nan Vintage Pinstripe Double Breasted Suit Refined Elegance
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0189',
    'Rose Nan Vintage Pinstripe Double Breasted Suit Refined Elegance',
    'Imported from main CSV - Rose Nan Vintage Pinstripe Double Breasted Suit Refined Elegance',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/nan_vintage-rose-pinstripe-double-breasted-suit-refined-elegance_2.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'nan-vintage-pinstripe-double-breasted-suit-refined-elegance',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 190: Black Shirt Dress Shirt
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SHI-CSV-0190',
    'Black Shirt Dress Shirt',
    'Imported from main CSV - Black Shirt Dress Shirt',
    65,
    'Shirts',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/shirt_black-dress-shirt_1.0.png',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'shirt-dress-shirt',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 191: Black Spiked Shoe Velvet Prom Spikes
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0191',
    'Black Spiked Shoe Velvet Prom Spikes',
    'Imported from main CSV - Black Spiked Shoe Velvet Prom Spikes',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/spiked-shoe_black-velvet-prom-spikes_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'spiked-shoe-velvet-prom-spikes',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 192: Black Black Spike Shoe ON Prom Spikes
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0192',
    'Black Black Spike Shoe ON Prom Spikes',
    'Imported from main CSV - Black Black Spike Shoe ON Prom Spikes',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/spike-shoe_black-on-black-prom-spikes_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'spike-shoe-on-prom-spikes',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 193: Grey Suit Mens Pinstripe Double Breasted Suit With Notched Lapel And Six Button Closure
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0193',
    'Grey Suit Mens Pinstripe Double Breasted Suit With Notched Lapel And Six Button Closure',
    'Imported from main CSV - Grey Suit Mens Pinstripe Double Breasted Suit With Notched Lapel And Six Button Closure',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/suit_mens-grey-pinstripe-double-breasted-suit-with-notched-lapel-and-six-button-closure_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'suit-mens-pinstripe-double-breasted-suit-with-notched-lapel-and-six-button-closure',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 194: Red Sweater Cardigan
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'KNI-CSV-0194',
    'Red Sweater Cardigan',
    'Imported from main CSV - Red Sweater Cardigan',
    79,
    'Knitwear',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/sweater_red-cardigan_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'sweater-cardigan',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 195: Blue Suit Slate Velvet Suit Luxury Elegance For
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0195',
    'Blue Suit Slate Velvet Suit Luxury Elegance For',
    'Imported from main CSV - Blue Suit Slate Velvet Suit Luxury Elegance For',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/suit_slate-blue-velvet-suit-luxury-elegance-for-2025_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'suit-slate-velvet-suit-luxury-elegance-for',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 196: Red Suspender Suspenders
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0196',
    'Red Suspender Suspenders',
    'Imported from main CSV - Red Suspender Suspenders',
    70,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/suspender_royal-blue-suspenders_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'suspender-suspenders',
        'total_images', 3,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 197: Turtleneck Slim Turtle Neck
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'KNI-CSV-0197',
    'Turtleneck Slim Turtle Neck',
    'Imported from main CSV - Turtleneck Slim Turtle Neck',
    79,
    'Knitwear',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/turtleneck_slim-turtle-neck_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'turtleneck-slim-turtle-neck',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 198: Black Turtleneck Cardigan
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'KNI-CSV-0198',
    'Black Turtleneck Cardigan',
    'Imported from main CSV - Black Turtleneck Cardigan',
    79,
    'Knitwear',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/turtleneck_black-cardigan_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'turtleneck-cardigan',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 199: Red Black Turtleneck Turtleneck With Design
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'KNI-CSV-0199',
    'Red Black Turtleneck Turtleneck With Design',
    'Imported from main CSV - Red Black Turtleneck Turtleneck With Design',
    104,
    'Knitwear',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/turtleneck_royal-turtleneck-with-black-design_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'turtleneck-turtleneck-with-design',
        'total_images', 3,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 200: Red Turtleneck Turtleneck
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'KNI-CSV-0200',
    'Red Turtleneck Turtleneck',
    'Imported from main CSV - Red Turtleneck Turtleneck',
    79,
    'Knitwear',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/turtleneck_black-turtleneck_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'turtleneck-turtleneck',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 201: Tan Black Turtleneck Turtleneck With Pattern
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'KNI-CSV-0201',
    'Tan Black Turtleneck Turtleneck With Pattern',
    'Imported from main CSV - Tan Black Turtleneck Turtleneck With Pattern',
    79,
    'Knitwear',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/turtleneck_black-turtleneck-with-white-pattern_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'turtleneck-turtleneck-with-pattern',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 202: Royal Royal Tuxedo ON Slim Tuxedo
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0202',
    'Royal Royal Tuxedo ON Slim Tuxedo',
    'Imported from main CSV - Royal Royal Tuxedo ON Slim Tuxedo',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/tuxedo_royal-on-royal-slim-tuxedo_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-on-slim-tuxedo',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 203: Black Black Tuxedo ON Tuxedo With Vest
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0203',
    'Black Black Tuxedo ON Tuxedo With Vest',
    'Imported from main CSV - Black Black Tuxedo ON Tuxedo With Vest',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/tuxedo_black-on-black-tuxedo-with-vest_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-on-tuxedo-with-vest',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 204: Tuxedo Vested Blush Tuxedo Jacket Kct Menswears Romantic Statement Piece
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0204',
    'Tuxedo Vested Blush Tuxedo Jacket Kct Menswears Romantic Statement Piece',
    'Imported from main CSV - Tuxedo Vested Blush Tuxedo Jacket Kct Menswears Romantic Statement Piece',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/tuxedo-vested_blush-tuxedo-jacket-kct-menswears-romantic-statement-piece_1.0.webp',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-vested-blush-tuxedo-jacket-kct-menswears-romantic-statement-piece',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 205: Navy Blue Tuxedo Vested Elegant And Midnight Paisley Tuxedo A Perfect Ensemble For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0205',
    'Navy Blue Tuxedo Vested Elegant And Midnight Paisley Tuxedo A Perfect Ensemble For Prom And Wedding Seasons',
    'Imported from main CSV - Navy Blue Tuxedo Vested Elegant And Midnight Paisley Tuxedo A Perfect Ensemble For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/tuxedo-vested_elegant-navy-and-midnight-blue-paisley-tuxedo-a-perfect-ensemble-for-2024-prom-and-wedding-seasons_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-vested-elegant-and-midnight-paisley-tuxedo-a-perfect-ensemble-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 206: Pink Tuxedo Vested Elegant Blush Paisley Tuxedo Suit With Satin Accents Perfect For Prom Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0206',
    'Pink Tuxedo Vested Elegant Blush Paisley Tuxedo Suit With Satin Accents Perfect For Prom Wedding Seasons',
    'Imported from main CSV - Pink Tuxedo Vested Elegant Blush Paisley Tuxedo Suit With Satin Accents Perfect For Prom Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/tuxedo-vested_elegant-blush-pink-paisley-tuxedo-suit-with-satin-accents-perfect-for-prom-wedding-seasons_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-vested-elegant-blush-paisley-tuxedo-suit-with-satin-accents-perfect-for-prom-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 207: Navy Tuxedo Vested Elegant Paisley Three Piece Tuxedo With Satin Lapel A Refined Choice For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0207',
    'Navy Tuxedo Vested Elegant Paisley Three Piece Tuxedo With Satin Lapel A Refined Choice For Prom And Wedding Seasons',
    'Imported from main CSV - Navy Tuxedo Vested Elegant Paisley Three Piece Tuxedo With Satin Lapel A Refined Choice For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/tuxedo-vested_elegant-navy-paisley-three-piece-tuxedo-with-satin-lapel-a-refined-choice-for-2024-prom-and-wedding-seasons_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-vested-elegant-paisley-three-piece-tuxedo-with-satin-lapel-a-refined-choice-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 208: White Tuxedo Vested Elegant All Flower Tuxedo A Dazzling Ensemble For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0208',
    'White Tuxedo Vested Elegant All Flower Tuxedo A Dazzling Ensemble For Prom And Wedding Seasons',
    'Imported from main CSV - White Tuxedo Vested Elegant All Flower Tuxedo A Dazzling Ensemble For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/tuxedo-vested_elegant-all-white-flower-tuxedo-a-dazzling-ensemble-for-2023-prom-and-wedding-seasons_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-vested-elegant-all-flower-tuxedo-a-dazzling-ensemble-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 209: Blue Tuxedo Vested Elegant Powdered Tuxedo A Chic Choice For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0209',
    'Blue Tuxedo Vested Elegant Powdered Tuxedo A Chic Choice For Prom And Wedding Seasons',
    'Imported from main CSV - Blue Tuxedo Vested Elegant Powdered Tuxedo A Chic Choice For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/tuxedo-vested_elegant-powdered-blue-tuxedo-a-chic-choice-for-prom-and-wedding-seasons_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-vested-elegant-powdered-tuxedo-a-chic-choice-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 210: Black Tuxedo Vested Elegant Paisley Three Piece Tuxedo With Velvet Lapel A Sophisticated Choice For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0210',
    'Black Tuxedo Vested Elegant Paisley Three Piece Tuxedo With Velvet Lapel A Sophisticated Choice For Prom And Wedding Seasons',
    'Imported from main CSV - Black Tuxedo Vested Elegant Paisley Three Piece Tuxedo With Velvet Lapel A Sophisticated Choice For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/tuxedo-vested_elegant-black-paisley-three-piece-tuxedo-with-velvet-lapel-a-sophisticated-choice-for-2024-prom-and-wedding-seasons_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-vested-elegant-paisley-three-piece-tuxedo-with-velvet-lapel-a-sophisticated-choice-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 211: Black Gold Tuxedo Vested Exquisite And Tuxedo A Luxurious Ensemble For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0211',
    'Black Gold Tuxedo Vested Exquisite And Tuxedo A Luxurious Ensemble For Prom And Wedding Seasons',
    'Imported from main CSV - Black Gold Tuxedo Vested Exquisite And Tuxedo A Luxurious Ensemble For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/tuxedo-vested_exquisite-black-and-gold-tuxedo-a-luxurious-ensemble-for-prom-and-wedding-seasons_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-vested-exquisite-and-tuxedo-a-luxurious-ensemble-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 212: Rose Gold Tuxedo Vested Exquisite With Blush Flower Tuxedo A Stunning Choice For Prom And Wedding Celebrations
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0212',
    'Rose Gold Tuxedo Vested Exquisite With Blush Flower Tuxedo A Stunning Choice For Prom And Wedding Celebrations',
    'Imported from main CSV - Rose Gold Tuxedo Vested Exquisite With Blush Flower Tuxedo A Stunning Choice For Prom And Wedding Celebrations',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/tuxedo-vested_exquisite-rose-gold-with-blush-flower-tuxedo-a-stunning-choice-for-prom-and-wedding-celebrations_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-vested-exquisite-with-blush-flower-tuxedo-a-stunning-choice-for-prom-and-wedding-celebrations',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 213: Cream Tuxedo Vested Exquisite Design Three Piece Tuxedo With Satin Lapel A Trendsetting Choice For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0213',
    'Cream Tuxedo Vested Exquisite Design Three Piece Tuxedo With Satin Lapel A Trendsetting Choice For Prom And Wedding Seasons',
    'Imported from main CSV - Cream Tuxedo Vested Exquisite Design Three Piece Tuxedo With Satin Lapel A Trendsetting Choice For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/tuxedo-vested_exquisite-cream-design-three-piece-tuxedo-with-satin-lapel-a-trendsetting-choice-for-2024-prom-and-wedding-seasons_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-vested-exquisite-design-three-piece-tuxedo-with-satin-lapel-a-trendsetting-choice-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 214: Navy Tuxedo Vested Kct Menswear Elegance Tuxedo Timeless Sophistication
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0214',
    'Navy Tuxedo Vested Kct Menswear Elegance Tuxedo Timeless Sophistication',
    'Imported from main CSV - Navy Tuxedo Vested Kct Menswear Elegance Tuxedo Timeless Sophistication',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/tuxedo-vested_kct-menswear-navy-elegance-tuxedo-timeless-sophistication_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-vested-kct-menswear-elegance-tuxedo-timeless-sophistication',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 215: Black White Tuxedo Vested Kct Menswear Classic Tuxedo Monochrome Majesty
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0215',
    'Black White Tuxedo Vested Kct Menswear Classic Tuxedo Monochrome Majesty',
    'Imported from main CSV - Black White Tuxedo Vested Kct Menswear Classic Tuxedo Monochrome Majesty',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/tuxedo-vested_kct-menswear-classic-black-white-tuxedo-monochrome-majesty_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-vested-kct-menswear-classic-tuxedo-monochrome-majesty',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 216: Gold Tuxedo Vested Luxurious All Satin Paisley Suit A Distinguished Selection For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0216',
    'Gold Tuxedo Vested Luxurious All Satin Paisley Suit A Distinguished Selection For Prom And Wedding Seasons',
    'Imported from main CSV - Gold Tuxedo Vested Luxurious All Satin Paisley Suit A Distinguished Selection For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/tuxedo-vested_luxurious-all-gold-satin-paisley-suit-a-distinguished-selection-for-prom-and-wedding-seasons_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-vested-luxurious-all-satin-paisley-suit-a-distinguished-selection-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 217: Ivory Tuxedo Vested Luxurious Paisley Tuxedo With Satin Highlights Perfect For Prom Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0217',
    'Ivory Tuxedo Vested Luxurious Paisley Tuxedo With Satin Highlights Perfect For Prom Wedding Seasons',
    'Imported from main CSV - Ivory Tuxedo Vested Luxurious Paisley Tuxedo With Satin Highlights Perfect For Prom Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/tuxedo-vested_luxurious-ivory-paisley-tuxedo-with-satin-highlights-perfect-for-prom-wedding-seasons_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-vested-luxurious-paisley-tuxedo-with-satin-highlights-perfect-for-prom-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 218: Black Tuxedo Vested Timeless Classic Tuxedo Kct Menswears Staple OF Elegance
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0218',
    'Black Tuxedo Vested Timeless Classic Tuxedo Kct Menswears Staple OF Elegance',
    'Imported from main CSV - Black Tuxedo Vested Timeless Classic Tuxedo Kct Menswears Staple OF Elegance',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/tuxedo-vested_timeless-classic-black-tuxedo-kct-menswears-staple-of-elegance_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-vested-timeless-classic-tuxedo-kct-menswears-staple-of-elegance',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 219: Orange Tuxedo Vested Striking Burnt Tuxedo The Ultimate Choice For Prom And Wedding Seasons
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0219',
    'Orange Tuxedo Vested Striking Burnt Tuxedo The Ultimate Choice For Prom And Wedding Seasons',
    'Imported from main CSV - Orange Tuxedo Vested Striking Burnt Tuxedo The Ultimate Choice For Prom And Wedding Seasons',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/tuxedo-vested_striking-burnt-orange-tuxedo-the-ultimate-choice-for-2024-prom-and-wedding-seasons_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-vested-striking-burnt-tuxedo-the-ultimate-choice-for-prom-and-wedding-seasons',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 220: Tuxedo Vested Rust Tuxedo Jacket Embrace Autumn Elegance With Kct Menswear
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0220',
    'Tuxedo Vested Rust Tuxedo Jacket Embrace Autumn Elegance With Kct Menswear',
    'Imported from main CSV - Tuxedo Vested Rust Tuxedo Jacket Embrace Autumn Elegance With Kct Menswear',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/tuxedo-vested_rust-tuxedo-jacket-embrace-autumn-elegance-with-kct-menswear_1.0.webp',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-vested-rust-tuxedo-jacket-embrace-autumn-elegance-with-kct-menswear',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 221: Ivory White Black Tuxedo Vested Tuxedo With Trim Modern Sophistication Kct
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0221',
    'Ivory White Black Tuxedo Vested Tuxedo With Trim Modern Sophistication Kct',
    'Imported from main CSV - Ivory White Black Tuxedo Vested Tuxedo With Trim Modern Sophistication Kct',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/tuxedo-vested_ivory-white-tuxedo-with-black-trim-modern-sophistication-kct_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-vested-tuxedo-with-trim-modern-sophistication-kct',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 222: Hunter Green Tuxedo Vested Tuxedo Jacket Kct Menswears Elegant Forest
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0222',
    'Hunter Green Tuxedo Vested Tuxedo Jacket Kct Menswears Elegant Forest',
    'Imported from main CSV - Hunter Green Tuxedo Vested Tuxedo Jacket Kct Menswears Elegant Forest',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/tuxedo-vested_hunter-green-tuxedo-jacket-kct-menswears-elegant-forest_1.0.webp',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-vested-tuxedo-jacket-kct-menswears-elegant-forest',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 223: Tuxedos Classic Prom Packages
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0223',
    'Tuxedos Classic Prom Packages',
    'Imported from main CSV - Tuxedos Classic Prom Packages',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/tuxedos_classic-prom-packages_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedos-classic-prom-packages',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 224: Purple Tuxedo Vested Vivid Tuxedo BY Kct Menswear Dare TO Stand Out
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0224',
    'Purple Tuxedo Vested Vivid Tuxedo BY Kct Menswear Dare TO Stand Out',
    'Imported from main CSV - Purple Tuxedo Vested Vivid Tuxedo BY Kct Menswear Dare TO Stand Out',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/tuxedo-vested_vivid-purple-tuxedo-by-kct-menswear-dare-to-stand-out_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedo-vested-vivid-tuxedo-by-kct-menswear-dare-to-stand-out',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 225: Tuxedos Combo
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0225',
    'Tuxedos Combo',
    'Imported from main CSV - Tuxedos Combo',
    324,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/tuxedos_new-combo-6_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedos-combo',
        'total_images', 5,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 226: Navy Blue Tuxedos Mens Double Breasted Tuxedo Modern Fit Piece Suit
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0226',
    'Navy Blue Tuxedos Mens Double Breasted Tuxedo Modern Fit Piece Suit',
    'Imported from main CSV - Navy Blue Tuxedos Mens Double Breasted Tuxedo Modern Fit Piece Suit',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/tuxedos_mens-black-double-breasted-tuxedo-modern-fit-2-piece-suit_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedos-mens-double-breasted-tuxedo-modern-fit-piece-suit',
        'total_images', 2,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 227: Royal Purple Tuxedos Mens Tuxedo Slim Fit Satin Lapel Suit
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0227',
    'Royal Purple Tuxedos Mens Tuxedo Slim Fit Satin Lapel Suit',
    'Imported from main CSV - Royal Purple Tuxedos Mens Tuxedo Slim Fit Satin Lapel Suit',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/tuxedos_mens-royal-purple-tuxedo-slim-fit-satin-lapel-suit_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedos-mens-tuxedo-slim-fit-satin-lapel-suit',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 228: Blue Tuxedos Men S Light Sequin Lapel Three Piece Prom Tuxedo A Statement IN Sophistication
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0228',
    'Blue Tuxedos Men S Light Sequin Lapel Three Piece Prom Tuxedo A Statement IN Sophistication',
    'Imported from main CSV - Blue Tuxedos Men S Light Sequin Lapel Three Piece Prom Tuxedo A Statement IN Sophistication',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/tuxedos_men-s-light-blue-sequin-lapel-three-piece-prom-tuxedo-a-statement-in-sophistication_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedos-men-s-light-sequin-lapel-three-piece-prom-tuxedo-a-statement-in-sophistication',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 229: Red Tuxedos Prom Packages
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0229',
    'Red Tuxedos Prom Packages',
    'Imported from main CSV - Red Tuxedos Prom Packages',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_4/tuxedos_red-prom-packages_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedos-prom-packages',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 230: Purple Royal Tuxedos Sequin Lapel Three Piece Prom Tuxedo A Statement IN Elegance
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'SUI-CSV-0230',
    'Purple Royal Tuxedos Sequin Lapel Three Piece Prom Tuxedo A Statement IN Elegance',
    'Imported from main CSV - Purple Royal Tuxedos Sequin Lapel Three Piece Prom Tuxedo A Statement IN Elegance',
    299,
    'Men's Suits',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/tuxedos_purple-sequin-lapel-three-piece-prom-tuxedo-a-royal-statement-in-elegance_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'tuxedos-sequin-lapel-three-piece-prom-tuxedo-a-statement-in-elegance',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 231: Vest Sparkle Vest And Bowtie
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0231',
    'Vest Sparkle Vest And Bowtie',
    'Imported from main CSV - Vest Sparkle Vest And Bowtie',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/tie_clean_batch_01/tie_clean_batch_02/vest_sparkle-vest-and-bowtie_1.0.jpg',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'vest-sparkle-vest-and-bowtie',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 232: Wedding Swatch Aqua Wedding Color
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0232',
    'Wedding Swatch Aqua Wedding Color',
    'Imported from main CSV - Wedding Swatch Aqua Wedding Color',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_3/wedding-swatch_aqua-wedding-color_1.0.png',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'wedding-swatch-aqua-wedding-color',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

-- Product 233: Purple Wedding Swatches Wedding Color
INSERT INTO products (
    sku, 
    name, 
    description, 
    price, 
    category, 
    status, 
    image_url, 
    metadata,
    created_at, 
    updated_at
) VALUES (
    'ACC-CSV-0233',
    'Purple Wedding Swatches Wedding Color',
    'Imported from main CSV - Purple Wedding Swatches Wedding Color',
    45,
    'Accessories',
    'active',
    'https://pub-5cd8c531c0034986bf6282a223bd0564.r2.dev/batch_1/batch_2/wedding-swatches_purple-wedding-color_1.0.png',
    jsonb_build_object(
        'source', 'main_csv',
        'original_slug', 'wedding-swatches-wedding-color',
        'total_images', 1,
        'import_date', '2025-08-12T16:40:10.371Z'
    ),
    NOW(),
    NOW()
);

COMMIT;

-- Verification queries
SELECT 
    category, 
    COUNT(*) as count,
    AVG(price) as avg_price
FROM products 
WHERE sku LIKE 'ACC-%' OR sku LIKE 'SHO-%' OR sku LIKE 'SUI-%' 
   OR sku LIKE 'OUT-%' OR sku LIKE 'KNI-%' OR sku LIKE 'SHI-%' OR sku LIKE 'FOR-%'
GROUP BY category
ORDER BY count DESC;

-- Check total products after import
SELECT COUNT(*) as total_products FROM products;
