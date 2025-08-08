/**
 * KEYBOARD SHORTCUTS HOOK
 * Adds productivity shortcuts for power users
 * Created: 2025-08-07
 */

import { useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { toast } from 'sonner';

interface ShortcutConfig {
  key: string;
  ctrl?: boolean;
  cmd?: boolean;
  shift?: boolean;
  alt?: boolean;
  handler: () => void;
  description?: string;
}

export function useKeyboardShortcuts(shortcuts: ShortcutConfig[]) {
  const handleKeyDown = useCallback((event: KeyboardEvent) => {
    shortcuts.forEach(shortcut => {
      const isCtrlPressed = shortcut.ctrl ? (event.ctrlKey || event.metaKey) : true;
      const isCmdPressed = shortcut.cmd ? event.metaKey : true;
      const isShiftPressed = shortcut.shift ? event.shiftKey : !shortcut.shift || event.shiftKey;
      const isAltPressed = shortcut.alt ? event.altKey : !shortcut.alt || event.altKey;
      
      const keyMatch = event.key.toLowerCase() === shortcut.key.toLowerCase() ||
                      event.code.toLowerCase() === shortcut.key.toLowerCase();
      
      if (keyMatch && isCtrlPressed && isCmdPressed && isShiftPressed && isAltPressed) {
        event.preventDefault();
        shortcut.handler();
      }
    });
  }, [shortcuts]);

  useEffect(() => {
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [handleKeyDown]);
}

/**
 * Global keyboard shortcuts for the admin panel
 */
export function useGlobalShortcuts() {
  const navigate = useNavigate();

  const shortcuts: ShortcutConfig[] = [
    // Navigation shortcuts
    {
      key: 'p',
      ctrl: true,
      handler: () => navigate('/admin/products'),
      description: 'Go to Products'
    },
    {
      key: 'o',
      ctrl: true,
      handler: () => navigate('/admin/orders'),
      description: 'Go to Orders'
    },
    {
      key: 'c',
      ctrl: true,
      shift: true,
      handler: () => navigate('/admin/customers'),
      description: 'Go to Customers'
    },
    {
      key: 'd',
      ctrl: true,
      handler: () => navigate('/admin'),
      description: 'Go to Dashboard'
    },
    // Search shortcut
    {
      key: 'k',
      ctrl: true,
      handler: () => {
        const searchInput = document.querySelector('input[type="search"], input[placeholder*="Search"]') as HTMLInputElement;
        if (searchInput) {
          searchInput.focus();
          searchInput.select();
        }
      },
      description: 'Focus search'
    },
    // Help shortcut
    {
      key: '?',
      shift: true,
      handler: () => {
        toast.info('Keyboard Shortcuts', {
          description: `
            Ctrl+P: Products
            Ctrl+O: Orders
            Ctrl+Shift+C: Customers
            Ctrl+D: Dashboard
            Ctrl+K: Search
            Ctrl+S: Save
            ESC: Close dialog
          `,
          duration: 5000
        });
      },
      description: 'Show help'
    }
  ];

  useKeyboardShortcuts(shortcuts);
}

/**
 * Product management specific shortcuts
 */
export function useProductShortcuts(
  onSave?: () => void,
  onNew?: () => void,
  onDuplicate?: () => void,
  onDelete?: () => void
) {
  const shortcuts: ShortcutConfig[] = [];

  if (onSave) {
    shortcuts.push({
      key: 's',
      ctrl: true,
      handler: () => {
        onSave();
        toast.success('Product saved');
      },
      description: 'Save product'
    });
  }

  if (onNew) {
    shortcuts.push({
      key: 'n',
      ctrl: true,
      handler: onNew,
      description: 'New product'
    });
  }

  if (onDuplicate) {
    shortcuts.push({
      key: 'd',
      ctrl: true,
      shift: true,
      handler: onDuplicate,
      description: 'Duplicate product'
    });
  }

  if (onDelete) {
    shortcuts.push({
      key: 'Delete',
      handler: onDelete,
      description: 'Delete product'
    });
  }

  // ESC to close modals
  shortcuts.push({
    key: 'Escape',
    handler: () => {
      const closeButton = document.querySelector('[aria-label="Close"], .dialog-close, [data-state="open"] button[type="button"]') as HTMLElement;
      if (closeButton) closeButton.click();
    },
    description: 'Close dialog'
  });

  useKeyboardShortcuts(shortcuts);
}

/**
 * Table navigation shortcuts
 */
export function useTableShortcuts(
  onSelectAll?: () => void,
  onDeselectAll?: () => void,
  onNextPage?: () => void,
  onPrevPage?: () => void
) {
  const shortcuts: ShortcutConfig[] = [];

  if (onSelectAll) {
    shortcuts.push({
      key: 'a',
      ctrl: true,
      handler: onSelectAll,
      description: 'Select all'
    });
  }

  if (onDeselectAll) {
    shortcuts.push({
      key: 'a',
      ctrl: true,
      shift: true,
      handler: onDeselectAll,
      description: 'Deselect all'
    });
  }

  if (onNextPage) {
    shortcuts.push({
      key: 'ArrowRight',
      alt: true,
      handler: onNextPage,
      description: 'Next page'
    });
  }

  if (onPrevPage) {
    shortcuts.push({
      key: 'ArrowLeft',
      alt: true,
      handler: onPrevPage,
      description: 'Previous page'
    });
  }

  useKeyboardShortcuts(shortcuts);
}