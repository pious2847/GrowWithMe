import os
import urllib.request
import zipfile
import hashlib
import json
import sys

hf_token = __import__("os").environ.get("HF_TOKEN", "")
hf_repo = "abdulhafis/growwithme-nana-slm"

files = [
    "adapter_model.safetensors",
    "adapter_config.json",
    "tokenizer.json",
    "tokenizer_config.json",
    "chat_template.jinja"
]

temp_dir = os.path.join(os.path.dirname(__file__), "temp_slm")
os.makedirs(temp_dir, exist_ok=True)

zip_filename = os.path.join(os.path.dirname(__file__), "nana_slm_v1.zip")

print(f"Downloading files from Hugging Face: {hf_repo}...")
headers = {
    "Authorization": f"Bearer {hf_token}"
}

for f in files:
    url = f"https://huggingface.co/{hf_repo}/resolve/main/{f}"
    dest = os.path.join(temp_dir, f)
    print(f"Downloading {f}...")
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as response, open(dest, "wb") as out_file:
            out_file.write(response.read())
    except Exception as e:
        print(f"Failed to download {f}: {e}")
        sys.exit(1)

print("Zipping files...")
try:
    with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for f in files:
            zipf.write(os.path.join(temp_dir, f), f)
except Exception as e:
    print(f"Failed to zip files: {e}")
    sys.exit(1)

# Calculate size and sha256
size_bytes = os.path.getsize(zip_filename)
sha256_hash = hashlib.sha256()
try:
    with open(zip_filename, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    sha_hash = sha256_hash.hexdigest()
except Exception as e:
    print(f"Failed to hash zip file: {e}")
    sys.exit(1)

# Clean up temp files
for f in files:
    temp_file_path = os.path.join(temp_dir, f)
    if os.path.exists(temp_file_path):
        os.remove(temp_file_path)
os.rmdir(temp_dir)

# Print output JSON
output = {
    "zipPath": os.path.abspath(zip_filename),
    "sizeBytes": size_bytes,
    "sha256": sha_hash
}
print("PACK_SUCCESS")
print(json.dumps(output))
sys.exit(0)
