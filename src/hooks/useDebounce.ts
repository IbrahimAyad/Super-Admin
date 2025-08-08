/**
 * DEBOUNCE HOOK
 * Optimizes search and input performance
 * Created: 2025-08-07
 */

import { useState, useEffect } from 'react';

/**
 * Debounces a value by the specified delay
 * Prevents excessive API calls and re-renders
 */
export function useDebounce<T>(value: T, delay: number = 300): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => {
      clearTimeout(handler);
    };
  }, [value, delay]);

  return debouncedValue;
}

/**
 * Returns a debounced callback function
 * Useful for event handlers that shouldn't fire too frequently
 */
export function useDebouncedCallback<T extends (...args: any[]) => any>(
  callback: T,
  delay: number = 300
): (...args: Parameters<T>) => void {
  const [timer, setTimer] = useState<NodeJS.Timeout | null>(null);

  return (...args: Parameters<T>) => {
    if (timer) clearTimeout(timer);
    
    const newTimer = setTimeout(() => {
      callback(...args);
    }, delay);
    
    setTimer(newTimer);
  };
}

/**
 * Debounced state setter
 * Combines state and debouncing in one hook
 */
export function useDebouncedState<T>(
  initialValue: T,
  delay: number = 300
): [T, T, (value: T) => void] {
  const [value, setValue] = useState<T>(initialValue);
  const debouncedValue = useDebounce(value, delay);

  return [value, debouncedValue, setValue];
}