/** @type {import('next').NextConfig} */
const nextConfig = {
    output: 'standalone',
    eslint: {
        ignoreDuringBuilds: true,
    },
    typescript: {
        ignoreBuildErrors: true,
    },
    devIndicators: {
        buildActivity: false,
        appIsrStatus: false,
    }
};

module.exports = nextConfig;
