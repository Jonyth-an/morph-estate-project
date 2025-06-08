/** @type {import('next').NextConfig} */
const nextConfig = {
    images: {
        remotePatterns: [
            {
                protocol: 'https',
                hostname: 'img.freepik.com'
            },
            {
                protocol: 'https',
                hostname: 'www.freepik.com'
            },
            {
                protocol: 'https',
                hostname: 'img.loom.com'
            }
        ]
    }
};

export default nextConfig;
