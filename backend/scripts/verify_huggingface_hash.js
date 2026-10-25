/**
 * Downloads the model from HuggingFace and verifies its SHA256 hash
 * Usage: node scripts/verify_huggingface_hash.js
 */
const https = require('https');
const crypto = require('crypto');

const HUGGINGFACE_URL = 'https://huggingface.co/abdulhafis/growwithme-nana-slm/resolve/main/nana_slm_v1.zip';

async function downloadAndHash(url) {
  return new Promise((resolve, reject) => {
    console.log(`Downloading from: ${url}`);
    console.log('This may take a moment...\n');

    https.get(url, (response) => {
      if (response.statusCode === 302 || response.statusCode === 301) {
        // Follow redirect
        console.log(`Following redirect to: ${response.headers.location}`);
        return downloadAndHash(response.headers.location).then(resolve).catch(reject);
      }

      if (response.statusCode !== 200) {
        reject(new Error(`HTTP ${response.statusCode}: ${response.statusMessage}`));
        return;
      }

      const hash = crypto.createHash('sha256');
      let totalBytes = 0;
      const contentLength = parseInt(response.headers['content-length'] || '0');

      response.on('data', (chunk) => {
        hash.update(chunk);
        totalBytes += chunk.length;
        
        if (contentLength > 0) {
          const progress = ((totalBytes / contentLength) * 100).toFixed(1);
          process.stdout.write(`\rDownloading: ${progress}% (${(totalBytes / 1024 / 1024).toFixed(2)} MB)`);
        }
      });

      response.on('end', () => {
        console.log('\n\nDownload complete!');
        const digest = hash.digest('hex');
        resolve({
          sha256: digest,
          sizeBytes: totalBytes,
        });
      });

      response.on('error', reject);
    }).on('error', reject);
  });
}

async function main() {
  console.log('==============================================');
  console.log(' HuggingFace Model Hash Verification');
  console.log('==============================================\n');

  try {
    const result = await downloadAndHash(HUGGINGFACE_URL);
    
    console.log('==============================================');
    console.log(' VERIFICATION COMPLETE');
    console.log('==============================================');
    console.log(`\nSHA256: ${result.sha256}`);
    console.log(`Size: ${(result.sizeBytes / 1024 / 1024).toFixed(2)} MB (${result.sizeBytes} bytes)`);
    
    console.log('\n----------------------------------------------');
    console.log('Compare with database:');
    console.log('----------------------------------------------');
    console.log('Expected SHA256: c41053c04bcedb1e90a2588995811bcc0a6d286b5d793ee49e02cfb94708916e');
    console.log(`Actual SHA256:   ${result.sha256}`);
    
    if (result.sha256 === 'c41053c04bcedb1e90a2588995811bcc0a6d286b5d793ee49e02cfb94708916e') {
      console.log('\n✓ MATCH! The hash is correct.');
    } else {
      console.log('\n✗ MISMATCH! You need to update the database with the correct hash.');
      console.log('\nRun this to update:');
      console.log(`node scripts/update_slm_hash.js "${result.sha256}" ${result.sizeBytes}`);
    }
  } catch (error) {
    console.error('\n==============================================');
    console.error(' VERIFICATION FAILED');
    console.error('==============================================');
    console.error(error.message);
    process.exit(1);
  }
}

main();
