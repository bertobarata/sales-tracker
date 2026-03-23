import sharp from 'sharp';

const sizes = [192, 512];

const svg = (size) => `
<svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" xmlns="http://www.w3.org/2000/svg">
  <rect width="${size}" height="${size}" rx="${size * 0.22}" fill="#2563eb"/>
  <text
    x="50%" y="54%"
    dominant-baseline="middle"
    text-anchor="middle"
    font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
    font-weight="800"
    font-size="${size * 0.38}"
    fill="white"
    letter-spacing="-${size * 0.01}"
  >ST</text>
</svg>`;

for (const size of sizes) {
  await sharp(Buffer.from(svg(size)))
    .png()
    .toFile(`public/icon-${size}.png`);
  console.log(`✓ icon-${size}.png`);
}
