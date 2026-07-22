import react from '@vitejs/plugin-react'
import { defineConfig, loadEnv } from 'vite'
import { VitePWA } from 'vite-plugin-pwa'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  return {
    base: env.VITE_BASE_PATH || '/',
    plugins: [
      react(),
      VitePWA({
        registerType: 'autoUpdate',
        workbox: {
          navigateFallback: 'index.html'
        },
        manifest: {
          name: 'Weedpreis – Neutraler Apothekenvergleich',
          short_name: 'Weedpreis',
          description: 'Neutraler Preis- und Verfügbarkeitsvergleich für Medizinalcannabis.',
          theme_color: '#07110f',
          background_color: '#07110f',
          display: 'standalone',
          start_url: '.',
          icons: [{ src: 'logo.svg', sizes: 'any', type: 'image/svg+xml', purpose: 'any maskable' }]
        }
      })
    ],
    test: {
      environment: 'jsdom',
      setupFiles: './vitest.setup.ts',
      include: ['src/**/*.test.ts', 'src/**/*.test.tsx']
    }
  }
})
