# KCT Menswear Complete Price Structure

## 📊 Official Price List by Category

### Accessories & Small Items
- **Socks**: $10.00
- **Pocket Square**: $10.00
- **Tie Clips**: $15.00
- **Bow Ties & Ties**: $24.99
- **Belts**: $29.99
- **Cufflinks**: $39.99
- **Suspenders**: $49.99

### Shirts & Tops
- **Dress Shirts (Regular)**: $39.99
- **Turtlenecks**: $44.99
- **Collarless Dress Shirts**: $49.99
- **Stretch Dress Shirts**: $59.99
- **Shiny Dress Shirts**: $69.99

### Pants
- **Dress Pants**: $59.99
- **Stretch Pants**: $69.99
- **Tuxedo Pants**: $69.99
- **Satin Pants**: $69.99

### Vests & Sets
- **Vest & Tie Sets**: $49.99

### Shoes
- **Loafers**: $79.99
- **Other Dress Shoes**: $89.99
- **Classic Dress Shoes**: $99.99
- **Spiked Shoes**: $99.99

### Sweaters & Outerwear
- **Premium Sweaters**: $129.99 - $149.99
- **Winter Jackets**: $199.99 - $249.99

### Blazers
- **Summer Blazers**: $199.99
- **Prom Blazers**: $199.99 - $249.99
- **Velvet Blazers**: $199.99, $229.99, $249.99
- **Sparkle Blazers**: $249.99

### Suits & Tuxedos
- **Men's Suits**: 
  - Standard: $179.99
  - Premium: $199.99
  - Deluxe: $229.99
  - Executive: $249.99
  - Luxury: $299.99
  - Ultra Premium: $329.99
  - Exclusive: $349.99

### Tuxedos
- Same pricing as suits: $179.99 - $349.99

## 💳 Stripe Price Mapping Strategy

### Use Existing Prices Where Possible:

**From Your Core Products:**
- $24.99 → `price_1RpvHlCHc12x7sCzp0TVNS92` (Tie price)
- $39.99 → `price_1RpvWnCHc12x7sCzzioA64qD` (Shirt price) 
- $99.97 → `price_1RpvQqCHc12x7sCzfRrWStZb` (5-tie bundle)
- $149.96 → `price_1RpvRACHc12x7sCzVYFZh6Ia` (8-tie bundle)
- $179.99 → `price_1Rpv2tCHc12x7sCzVvLRto3m` (2-piece suit)
- $199.00 → `price_1RpvZUCHc12x7sCzM4sp9DY5` (Starter bundle)
- $229.99 → `price_1Rpv31CHc12x7sCzlFtlUflr` (3-piece suit)
- $249.99 → `price_1RpvZtCHc12x7sCzny7VmEWD` (Professional bundle)
- $299.99 → `price_1RpvfvCHc12x7sCzq1jYfG9o` (Premium bundle)

### Need to Create New Prices:
- $10.00 (Socks, Pocket squares)
- $15.00 (Tie clips)
- $29.99 (Belts)
- $44.99 (Turtlenecks)
- $49.99 (Vests, Collarless shirts, Suspenders)
- $59.99 (Dress pants, Stretch shirts)
- $69.99 (Shiny shirts, Special pants)
- $79.99 (Loafers)
- $89.99 (Other dress shoes)
- $129.99 (Premium sweaters)
- $329.99 (Ultra premium suits)
- $349.99 (Exclusive suits)

## 🔢 Price Points Summary

### Total Unique Price Points: 25
1. $10.00
2. $15.00
3. $24.99
4. $29.99
5. $39.99
6. $44.99
7. $49.99
8. $59.99
9. $69.99
10. $79.99
11. $89.99
12. $99.99
13. $129.99
14. $149.99
15. $179.99
16. $199.99
17. $229.99
18. $249.99
19. $299.99
20. $329.99
21. $349.99

### Already Have in Stripe: ~10 prices
### Need to Create: ~15 prices

## 📝 Database Price Mapping

All prices stored in cents:
- $10.00 = 1000
- $15.00 = 1500
- $24.99 = 2499
- $29.99 = 2999
- $39.99 = 3999
- $44.99 = 4499
- $49.99 = 4999
- $59.99 = 5999
- $69.99 = 6999
- $79.99 = 7999
- $89.99 = 8999
- $99.99 = 9999
- $129.99 = 12999
- $149.99 = 14999
- $179.99 = 17999
- $199.99 = 19999
- $229.99 = 22999
- $249.99 = 24999
- $299.99 = 29999
- $329.99 = 32999
- $349.99 = 34999

## 🎯 Implementation Strategy

### Option 1: Create Missing Prices (Recommended)
Create the ~15 missing prices in Stripe as standard prices, then map all products to these 25 total prices.

### Option 2: Consolidate to Tiers
Group similar prices:
- Budget: $10-29
- Standard: $39-69
- Premium: $79-99
- Luxury: $129-179
- Executive: $199-249
- Ultra: $299-349

This comprehensive price structure covers all KCT Menswear products!