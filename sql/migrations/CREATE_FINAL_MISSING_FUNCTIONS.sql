-- ============================================
-- CREATE FINAL MISSING FUNCTIONS
-- ============================================

-- 1. Generate Analytics Report Function
CREATE OR REPLACE FUNCTION generate_analytics_report(
  p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
  p_end_date DATE DEFAULT CURRENT_DATE,
  p_report_type TEXT DEFAULT 'summary'
)
RETURNS JSONB AS $$
DECLARE
  v_report JSONB;
BEGIN
  -- Build comprehensive analytics report
  v_report := jsonb_build_object(
    'report_type', p_report_type,
    'period', jsonb_build_object(
      'start_date', p_start_date,
      'end_date', p_end_date,
      'days', p_end_date - p_start_date
    ),
    'sales', (
      SELECT jsonb_build_object(
        'total_orders', COUNT(*),
        'total_revenue', COALESCE(SUM(total_amount), 0) / 100.0,
        'average_order_value', COALESCE(AVG(total_amount), 0) / 100.0,
        'conversion_rate', 0 -- Would need sessions data
      )
      FROM orders
      WHERE created_at::DATE BETWEEN p_start_date AND p_end_date
        AND financial_status = 'paid'
    ),
    'customers', (
      SELECT jsonb_build_object(
        'new_customers', COUNT(*) FILTER (WHERE created_at::DATE BETWEEN p_start_date AND p_end_date),
        'returning_customers', COUNT(*) FILTER (WHERE EXISTS (
          SELECT 1 FROM orders o 
          WHERE o.customer_id = customers.id 
          AND o.created_at < p_start_date
        )),
        'total_customers', COUNT(*)
      )
      FROM customers
    ),
    'products', (
      SELECT jsonb_build_object(
        'top_selling', (
          SELECT jsonb_agg(
            jsonb_build_object(
              'product_name', product_name,
              'units_sold', units_sold,
              'revenue', revenue
            ) ORDER BY revenue DESC
          )
          FROM (
            SELECT 
              p.name as product_name,
              SUM((item->>'quantity')::INTEGER) as units_sold,
              SUM((item->>'total_price')::DECIMAL / 100) as revenue
            FROM orders o
            CROSS JOIN LATERAL jsonb_array_elements(o.items) AS item
            JOIN products p ON p.id = (item->>'product_id')::UUID
            WHERE o.created_at::DATE BETWEEN p_start_date AND p_end_date
              AND o.financial_status = 'paid'
            GROUP BY p.id, p.name
            ORDER BY revenue DESC
            LIMIT 10
          ) top_products
        ),
        'low_stock', (
          SELECT COUNT(*)
          FROM product_variants
          WHERE COALESCE(available_quantity, inventory_quantity, 0) < 10
        )
      )
    ),
    'inventory', (
      SELECT jsonb_build_object(
        'total_stock_value', COALESCE(SUM(
          COALESCE(available_quantity, inventory_quantity, 0) * price
        ), 0) / 100.0,
        'low_stock_items', COUNT(*) FILTER (
          WHERE COALESCE(available_quantity, inventory_quantity, 0) < 10
        ),
        'out_of_stock_items', COUNT(*) FILTER (
          WHERE COALESCE(available_quantity, inventory_quantity, 0) = 0
        )
      )
      FROM product_variants
    ),
    'orders_by_status', (
      SELECT jsonb_object_agg(
        status,
        count
      )
      FROM (
        SELECT status, COUNT(*) as count
        FROM orders
        WHERE created_at::DATE BETWEEN p_start_date AND p_end_date
        GROUP BY status
      ) status_counts
    ),
    'daily_breakdown', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'date', order_date,
          'orders', order_count,
          'revenue', revenue
        ) ORDER BY order_date
      )
      FROM (
        SELECT 
          created_at::DATE as order_date,
          COUNT(*) as order_count,
          SUM(total_amount) / 100.0 as revenue
        FROM orders
        WHERE created_at::DATE BETWEEN p_start_date AND p_end_date
          AND financial_status = 'paid'
        GROUP BY created_at::DATE
      ) daily_data
    ),
    'generated_at', NOW()
  );
  
  RETURN v_report;
END;
$$ LANGUAGE plpgsql;

-- 2. Process Bulk Orders Function
CREATE OR REPLACE FUNCTION process_bulk_orders(
  p_order_ids UUID[],
  p_action TEXT, -- 'confirm', 'ship', 'cancel', 'refund'
  p_metadata JSONB DEFAULT '{}'
)
RETURNS JSONB AS $$
DECLARE
  v_processed INTEGER := 0;
  v_failed INTEGER := 0;
  v_errors JSONB := '[]'::jsonb;
  v_order_id UUID;
  v_current_status TEXT;
BEGIN
  -- Validate action
  IF p_action NOT IN ('confirm', 'ship', 'cancel', 'refund', 'deliver') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Invalid action: ' || p_action
    );
  END IF;
  
  -- Process each order
  FOREACH v_order_id IN ARRAY p_order_ids
  LOOP
    BEGIN
      -- Get current status
      SELECT status INTO v_current_status
      FROM orders WHERE id = v_order_id;
      
      IF NOT FOUND THEN
        v_failed := v_failed + 1;
        v_errors := v_errors || jsonb_build_object(
          'order_id', v_order_id,
          'error', 'Order not found'
        );
        CONTINUE;
      END IF;
      
      -- Perform action based on type
      CASE p_action
        WHEN 'confirm' THEN
          IF v_current_status = 'pending' THEN
            UPDATE orders 
            SET 
              status = 'confirmed',
              confirmed_at = NOW(),
              updated_at = NOW()
            WHERE id = v_order_id;
            v_processed := v_processed + 1;
          ELSE
            v_failed := v_failed + 1;
            v_errors := v_errors || jsonb_build_object(
              'order_id', v_order_id,
              'error', 'Cannot confirm order in status: ' || v_current_status
            );
          END IF;
          
        WHEN 'ship' THEN
          IF v_current_status IN ('confirmed', 'processing') THEN
            UPDATE orders 
            SET 
              status = 'shipped',
              shipped_at = NOW(),
              tracking_number = p_metadata->>'tracking_number',
              carrier_name = p_metadata->>'carrier',
              updated_at = NOW()
            WHERE id = v_order_id;
            v_processed := v_processed + 1;
          ELSE
            v_failed := v_failed + 1;
            v_errors := v_errors || jsonb_build_object(
              'order_id', v_order_id,
              'error', 'Cannot ship order in status: ' || v_current_status
            );
          END IF;
          
        WHEN 'deliver' THEN
          IF v_current_status = 'shipped' THEN
            UPDATE orders 
            SET 
              status = 'delivered',
              delivered_at = NOW(),
              updated_at = NOW()
            WHERE id = v_order_id;
            v_processed := v_processed + 1;
          ELSE
            v_failed := v_failed + 1;
            v_errors := v_errors || jsonb_build_object(
              'order_id', v_order_id,
              'error', 'Cannot deliver order in status: ' || v_current_status
            );
          END IF;
          
        WHEN 'cancel' THEN
          IF v_current_status NOT IN ('delivered', 'refunded') THEN
            UPDATE orders 
            SET 
              status = 'cancelled',
              cancelled_at = NOW(),
              cancellation_reason = p_metadata->>'reason',
              updated_at = NOW()
            WHERE id = v_order_id;
            v_processed := v_processed + 1;
          ELSE
            v_failed := v_failed + 1;
            v_errors := v_errors || jsonb_build_object(
              'order_id', v_order_id,
              'error', 'Cannot cancel order in status: ' || v_current_status
            );
          END IF;
          
        WHEN 'refund' THEN
          IF v_current_status IN ('delivered', 'cancelled', 'confirmed', 'processing', 'shipped') THEN
            -- Create refund request
            INSERT INTO refund_requests (
              order_id,
              refund_amount,
              reason,
              status,
              created_at
            ) VALUES (
              v_order_id,
              (SELECT total_amount FROM orders WHERE id = v_order_id),
              p_metadata->>'reason',
              'pending',
              NOW()
            );
            
            UPDATE orders 
            SET 
              financial_status = 'refund_pending',
              updated_at = NOW()
            WHERE id = v_order_id;
            
            v_processed := v_processed + 1;
          ELSE
            v_failed := v_failed + 1;
            v_errors := v_errors || jsonb_build_object(
              'order_id', v_order_id,
              'error', 'Cannot refund order in status: ' || v_current_status
            );
          END IF;
      END CASE;
      
    EXCEPTION
      WHEN OTHERS THEN
        v_failed := v_failed + 1;
        v_errors := v_errors || jsonb_build_object(
          'order_id', v_order_id,
          'error', SQLERRM
        );
    END;
  END LOOP;
  
  -- Log bulk operation
  INSERT INTO order_events (
    order_id,
    event_type,
    event_data,
    description,
    created_at
  )
  SELECT 
    unnest(p_order_ids),
    'bulk_' || p_action,
    jsonb_build_object(
      'action', p_action,
      'metadata', p_metadata,
      'batch_size', array_length(p_order_ids, 1)
    ),
    'Bulk operation: ' || p_action,
    NOW()
  WHERE v_processed > 0;
  
  RETURN jsonb_build_object(
    'success', v_failed = 0,
    'processed', v_processed,
    'failed', v_failed,
    'total', array_length(p_order_ids, 1),
    'errors', v_errors,
    'action', p_action
  );
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION generate_analytics_report(DATE, DATE, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION process_bulk_orders(UUID[], TEXT, JSONB) TO authenticated;

-- ============================================
-- VERIFICATION
-- ============================================

SELECT 
  'Final Functions Check' as status,
  routine_name,
  'CREATED ✅' as result
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'generate_analytics_report',
    'process_bulk_orders'
  )
ORDER BY routine_name;