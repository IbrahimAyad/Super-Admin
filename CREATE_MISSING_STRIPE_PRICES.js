// Script to Create Missing Stripe Prices
// These are the prices that don't exist in your core products

const stripe = require('stripe')('sk_live_YOUR_SECRET_KEY'); // Replace with your key

// Prices that need to be created
const pricesToCreate = [
  { amount: 1000, nickname: 'Accessories - Socks/Pocket Square' },
  { amount: 1500, nickname: 'Accessories - Tie Clips' },
  { amount: 2999, nickname: 'Accessories - Belts' },
  { amount: 4499, nickname: 'Shirts - Turtlenecks' },
  { amount: 4999, nickname: 'Vests & Accessories - Standard' },
  { amount: 5999, nickname: 'Pants - Dress Pants' },
  { amount: 6999, nickname: 'Premium Pants - Tuxedo/Satin' },
  { amount: 7999, nickname: 'Shoes - Loafers' },
  { amount: 8999, nickname: 'Shoes - Dress Shoes' },
  { amount: 12999, nickname: 'Sweaters - Premium' },
  { amount: 32999, nickname: 'Suits - Ultra Premium' },
  { amount: 34999, nickname: 'Suits - Exclusive' }
];

async function createMissingPrices() {
  console.log('Creating missing Stripe prices...\n');
  
  // First, get or create a standard product to attach prices to
  let standardProduct;
  
  try {
    // Try to find your existing product
    const products = await stripe.products.list({ limit: 100 });
    standardProduct = products.data.find(p => 
      p.name.includes('Premium') || p.name.includes('Business Suit')
    );
    
    if (!standardProduct) {
      // Create a new standard product
      standardProduct = await stripe.products.create({
        name: 'KCT Menswear Standard Product',
        description: 'Standard product for all KCT Menswear items',
        metadata: {
          type: 'standard_product'
        }
      });
    }
    
    console.log(`Using product: ${standardProduct.name} (${standardProduct.id})\n`);
    
  } catch (error) {
    console.error('Error finding/creating product:', error);
    return;
  }
  
  // Create each missing price
  const createdPrices = [];
  
  for (const priceConfig of pricesToCreate) {
    try {
      // Check if price already exists
      const existingPrices = await stripe.prices.list({
        product: standardProduct.id,
        limit: 100
      });
      
      const exists = existingPrices.data.find(p => 
        p.unit_amount === priceConfig.amount
      );
      
      if (exists) {
        console.log(`✅ Price already exists: $${(priceConfig.amount / 100).toFixed(2)} - ${exists.id}`);
        createdPrices.push({
          amount: priceConfig.amount,
          price_id: exists.id,
          nickname: priceConfig.nickname
        });
      } else {
        // Create new price
        const newPrice = await stripe.prices.create({
          product: standardProduct.id,
          unit_amount: priceConfig.amount,
          currency: 'usd',
          nickname: priceConfig.nickname,
          metadata: {
            category: 'standard_price'
          }
        });
        
        console.log(`✅ Created: $${(priceConfig.amount / 100).toFixed(2)} - ${newPrice.id}`);
        createdPrices.push({
          amount: priceConfig.amount,
          price_id: newPrice.id,
          nickname: priceConfig.nickname
        });
      }
      
      // Small delay to avoid rate limits
      await new Promise(resolve => setTimeout(resolve, 500));
      
    } catch (error) {
      console.error(`❌ Failed to create $${(priceConfig.amount / 100).toFixed(2)}:`, error.message);
    }
  }
  
  // Output SQL update statements
  console.log('\n=== SQL UPDATE STATEMENTS ===\n');
  console.log('-- Copy these to update your database:\n');
  
  createdPrices.forEach(price => {
    const dollarAmount = (price.amount / 100).toFixed(2);
    console.log(`-- $${dollarAmount} - ${price.nickname}`);
    console.log(`UPDATE product_variants SET stripe_price_id = '${price.price_id}', stripe_active = true WHERE price = ${price.amount} AND stripe_price_id LIKE 'NEED_TO_CREATE%';`);
    console.log('');
  });
  
  console.log('=== DONE ===');
}

// Run the script
createMissingPrices().catch(console.error);