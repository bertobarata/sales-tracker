import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'node',
    setupFiles: ['src/utils/test-setup.js'],
    coverage: {
      provider: 'v8',
      include: ['src/utils/**'],
      exclude: ['src/utils/sync.js', 'src/utils/test-setup.js'],
      thresholds: { lines: 70, functions: 70 },
    },
  },
})
