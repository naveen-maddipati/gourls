import { defineConfig } from 'vite';

export default defineConfig({
  server: {
    host: '0.0.0.0', // Allow all hosts
  // Explicitly allow these hostnames (include host:port variants) to avoid Vite host checks
  allowedHosts: ['go', 'go:4200', 'go.local', 'gourls.local', 'localhost', 'localhost:4200', '127.0.0.1'],
    strictPort: false,
    hmr: {
      host: 'localhost'
    }
  },
  preview: {
    host: '0.0.0.0', // Allow all hosts in preview mode
    allowedHosts: ['go', 'go.local', 'gourls.local', 'localhost'],
    strictPort: false
  },
  define: {
    // Disable host checking in production builds
    'import.meta.env.VITE_DISABLE_HOST_CHECK': JSON.stringify(true)
  }
});