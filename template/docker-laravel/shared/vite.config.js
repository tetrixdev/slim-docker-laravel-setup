import { defineConfig, loadEnv } from 'vite';
import laravel from 'laravel-vite-plugin';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig(({ mode }) => {
    const env = loadEnv(mode, process.cwd(), '');
    const vitePort = parseInt(env.VITE_PORT || '5173');
    const appUrl = new URL(env.APP_URL || 'http://localhost');

    return {
        plugins: [
            laravel({
                input: ['resources/css/app.css', 'resources/js/app.js'],
                refresh: true,
            }),
            tailwindcss(),
        ],
        server: {
            host: '0.0.0.0',
            port: 5173,
            hmr: {
                host: appUrl.hostname,
                clientPort: vitePort,
            },
            watch: {
                ignored: ['**/storage/framework/views/**'],
            },
        },
    };
});
