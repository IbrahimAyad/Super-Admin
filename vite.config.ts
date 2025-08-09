import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";
import { componentTagger } from "lovable-tagger";
import { visualizer } from "rollup-plugin-visualizer";

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => ({
  server: {
    host: "::",
    port: 3001,
  },
  plugins: [
    react(),
    mode === 'development' && componentTagger(),
    // Bundle size analyzer (run with: npm run build -- --mode analyze)
    mode === 'analyze' && visualizer({
      open: true,
      gzipSize: true,
      brotliSize: true,
      filename: 'dist/stats.html'
    })
  ].filter(Boolean),
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  build: {
    // Production optimizations
    target: 'es2020',
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true, // Remove console logs in production
        drop_debugger: true, // Remove debugger statements
        pure_funcs: ['console.log', 'console.info', 'console.debug'], // Remove specific console methods
        passes: 2, // Run compress passes twice for better optimization
      },
      mangle: {
        safari10: true, // Work around Safari 10 bugs
      },
      format: {
        comments: false, // Remove all comments
      },
    },
    // Output optimizations
    rollupOptions: {
      output: {
        // Manual chunking for better caching
        manualChunks: {
          // Vendor chunks
          'react-vendor': ['react', 'react-dom', 'react-router-dom'],
          'ui-vendor': ['@radix-ui/react-dialog', '@radix-ui/react-dropdown-menu', '@radix-ui/react-select', '@radix-ui/react-tabs'],
          'utils-vendor': ['clsx', 'tailwind-merge', 'class-variance-authority', 'date-fns'],
          'query-vendor': ['@tanstack/react-query'],
          'supabase-vendor': ['@supabase/supabase-js'],
          'stripe-vendor': ['@stripe/stripe-js'],
          // Feature chunks
          'admin': [
            './src/pages/AdminDashboard.tsx',
            './src/components/admin/AdminSidebar.tsx',
          ],
          'auth': [
            './src/contexts/AuthContext.tsx',
            './src/components/auth/AdminRoute.tsx',
          ],
        },
        // Asset naming for better caching
        assetFileNames: (assetInfo) => {
          const info = assetInfo.name.split('.');
          const ext = info[info.length - 1];
          if (/png|jpe?g|svg|gif|tiff|bmp|ico/i.test(ext)) {
            return `assets/images/[name]-[hash][extname]`;
          }
          if (/woff|woff2|eot|ttf|otf/i.test(ext)) {
            return `assets/fonts/[name]-[hash][extname]`;
          }
          return `assets/[name]-[hash][extname]`;
        },
        chunkFileNames: 'js/[name]-[hash].js',
        entryFileNames: 'js/[name]-[hash].js',
      },
    },
    // Build performance
    reportCompressedSize: false, // Disable gzip size reporting for faster builds
    chunkSizeWarningLimit: 1000, // Warn for chunks over 1MB
    // Source maps for production debugging (optional - disable for smaller builds)
    sourcemap: mode === 'production' ? 'hidden' : true,
  },
  // Dependency optimization
  optimizeDeps: {
    include: [
      'react',
      'react-dom',
      'react-router-dom',
      '@supabase/supabase-js',
      '@tanstack/react-query',
    ],
    exclude: ['@vite/client', '@vite/env'],
  },
  // Performance optimizations
  esbuild: {
    logOverride: { 'this-is-undefined-in-esm': 'silent' },
    treeShaking: true,
  },
  // Preview server configuration (for testing production build)
  preview: {
    port: 8080,
    strictPort: true,
  },
}));