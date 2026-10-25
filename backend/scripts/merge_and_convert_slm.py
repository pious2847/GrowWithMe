#!/usr/bin/env python3
"""
Merge LoRA adapter with base model and convert to GGUF for mobile deployment

Usage:
    python merge_and_convert_slm.py [--quantization Q4_K_M]

Requirements:
    pip install transformers peft torch huggingface_hub
"""

import os
import sys
import argparse
import subprocess
from pathlib import Path

def check_requirements():
    """Check if required packages are installed"""
    try:
        import transformers
        import peft
        import torch
        import huggingface_hub
        print("✓ All required packages installed")
        return True
    except ImportError as e:
        print(f"✗ Missing package: {e}")
        print("\nPlease install requirements:")
        print("pip install transformers peft torch huggingface_hub")
        return False

def merge_lora():
    """Merge LoRA adapter with base Llama model"""
    from transformers import AutoModelForCausalLM, AutoTokenizer
    from peft import PeftModel
    import torch
    
    print("\n" + "="*70)
    print("STEP 1: Merging LoRA Adapter with Base Model")
    print("="*70)
    
    base_model_name = "meta-llama/Llama-3.2-1B-Instruct"
    adapter_name = "abdulhafis/growwithme-nana-slm"
    output_dir = "./nana-slm-merged"
    
    print(f"\n1. Loading base model: {base_model_name}")
    print("   (This may take a few minutes...)")
    
    try:
        base_model = AutoModelForCausalLM.from_pretrained(
            base_model_name,
            torch_dtype=torch.float16,
            device_map="cpu",
            low_cpu_mem_usage=True,
        )
        print("   ✓ Base model loaded")
    except Exception as e:
        print(f"   ✗ Failed to load base model: {e}")
        return False
    
    print(f"\n2. Loading LoRA adapter: {adapter_name}")
    
    try:
        model = PeftModel.from_pretrained(base_model, adapter_name)
        print("   ✓ Adapter loaded")
    except Exception as e:
        print(f"   ✗ Failed to load adapter: {e}")
        return False
    
    print("\n3. Merging adapter into base model...")
    
    try:
        merged_model = model.merge_and_unload()
        print("   ✓ Merge complete")
    except Exception as e:
        print(f"   ✗ Failed to merge: {e}")
        return False
    
    print(f"\n4. Saving merged model to: {output_dir}")
    
    try:
        merged_model.save_pretrained(output_dir)
        
        # Also save tokenizer
        tokenizer = AutoTokenizer.from_pretrained(base_model_name)
        tokenizer.save_pretrained(output_dir)
        
        print("   ✓ Merged model saved")
        return True
    except Exception as e:
        print(f"   ✗ Failed to save: {e}")
        return False

def check_llama_cpp():
    """Check if llama.cpp is available"""
    llama_cpp_dir = Path("./llama.cpp")
    
    if not llama_cpp_dir.exists():
        print("\n" + "="*70)
        print("llama.cpp not found")
        print("="*70)
        print("\nTo convert to GGUF, you need llama.cpp:")
        print("  git clone https://github.com/ggerganov/llama.cpp")
        print("  cd llama.cpp")
        print("  make  # or: cmake . && make")
        print("\nThen run this script again.")
        return False
    
    return True

def convert_to_gguf(quantization="Q4_K_M"):
    """Convert merged model to GGUF format"""
    print("\n" + "="*70)
    print("STEP 2: Converting to GGUF Format")
    print("="*70)
    
    merged_dir = "./nana-slm-merged"
    fp16_output = "./nana-slm-f16.gguf"
    quant_output = f"./nana-slm-{quantization.lower()}.gguf"
    
    llama_cpp = Path("./llama.cpp")
    
    # Convert to FP16 GGUF
    print(f"\n1. Converting to FP16 GGUF: {fp16_output}")
    
    convert_script = llama_cpp / "convert_hf_to_gguf.py"
    
    try:
        result = subprocess.run(
            [
                sys.executable,
                str(convert_script),
                merged_dir,
                "--outfile", fp16_output,
                "--outtype", "f16",
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        print("   ✓ FP16 GGUF created")
    except subprocess.CalledProcessError as e:
        print(f"   ✗ Conversion failed: {e.stderr}")
        return False
    
    # Quantize
    print(f"\n2. Quantizing to {quantization}: {quant_output}")
    
    quantize_tool = llama_cpp / "llama-quantize"
    if not quantize_tool.exists():
        quantize_tool = llama_cpp / "llama-quantize.exe"  # Windows
    
    if not quantize_tool.exists():
        print("   ✗ llama-quantize not found")
        print("   Please build llama.cpp first:")
        print("   cd llama.cpp && make")
        return False
    
    try:
        result = subprocess.run(
            [
                str(quantize_tool),
                fp16_output,
                quant_output,
                quantization,
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        print(f"   ✓ Quantized model created: {quant_output}")
        
        # Show file size
        size_mb = Path(quant_output).stat().st_size / (1024 * 1024)
        print(f"   File size: {size_mb:.2f} MB")
        
        return True
    except subprocess.CalledProcessError as e:
        print(f"   ✗ Quantization failed: {e.stderr}")
        return False

def test_gguf(gguf_file):
    """Test the GGUF model"""
    print("\n" + "="*70)
    print("STEP 3: Testing GGUF Model (Optional)")
    print("="*70)
    
    llama_cli = Path("./llama.cpp/llama-cli")
    if not llama_cli.exists():
        llama_cli = Path("./llama.cpp/llama-cli.exe")
    
    if not llama_cli.exists():
        print("\nllama-cli not found - skipping test")
        print("You can test manually later with:")
        print(f"  ./llama.cpp/llama-cli -m {gguf_file} -p 'Test prompt' -n 50")
        return
    
    print("\nTesting with a simple prompt...")
    
    test_prompt = "You are Nana, a maternal health assistant. A mother asks: What foods should I eat while pregnant? Answer briefly."
    
    try:
        result = subprocess.run(
            [
                str(llama_cli),
                "-m", gguf_file,
                "-p", test_prompt,
                "-n", "80",
                "-c", "2048",
                "--temp", "0.7",
            ],
            check=True,
            capture_output=True,
            text=True,
            timeout=60,
        )
        
        print("\n--- Model Response ---")
        print(result.stdout)
        print("--- End Response ---\n")
        print("✓ Model tested successfully!")
        
    except subprocess.TimeoutExpired:
        print("✗ Test timed out (model may be too slow)")
    except subprocess.CalledProcessError as e:
        print(f"✗ Test failed: {e.stderr}")
    except Exception as e:
        print(f"✗ Test error: {e}")

def calculate_sha256(file_path):
    """Calculate SHA256 hash of file"""
    import hashlib
    
    print(f"\nCalculating SHA256 for {file_path}...")
    
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    
    return sha256_hash.hexdigest()

def main():
    parser = argparse.ArgumentParser(
        description="Merge LoRA and convert to GGUF for mobile deployment"
    )
    parser.add_argument(
        "--quantization",
        choices=["Q2_K", "Q3_K_M", "Q4_K_M", "Q5_K_M", "Q6_K"],
        default="Q4_K_M",
        help="Quantization level (default: Q4_K_M, ~400MB)",
    )
    parser.add_argument(
        "--skip-merge",
        action="store_true",
        help="Skip merge step if already done",
    )
    parser.add_argument(
        "--skip-test",
        action="store_true",
        help="Skip testing the GGUF model",
    )
    
    args = parser.parse_args()
    
    print("\n" + "="*70)
    print("GrowWithMe Nana SLM Conversion Pipeline")
    print("="*70)
    print(f"\nQuantization: {args.quantization}")
    
    # Check requirements
    if not check_requirements():
        return 1
    
    # Step 1: Merge LoRA
    if not args.skip_merge:
        if not merge_lora():
            print("\n✗ Merge failed. Aborting.")
            return 1
    else:
        print("\nSkipping merge step (--skip-merge)")
        if not Path("./nana-slm-merged").exists():
            print("✗ Merged model not found!")
            return 1
    
    # Check llama.cpp
    if not check_llama_cpp():
        return 1
    
    # Step 2: Convert to GGUF
    if not convert_to_gguf(args.quantization):
        print("\n✗ GGUF conversion failed. Aborting.")
        return 1
    
    # Step 3: Test (optional)
    gguf_file = f"./nana-slm-{args.quantization.lower()}.gguf"
    
    if not args.skip_test:
        test_gguf(gguf_file)
    
    # Calculate SHA256
    sha256 = calculate_sha256(gguf_file)
    file_size = Path(gguf_file).stat().st_size
    
    # Final summary
    print("\n" + "="*70)
    print("CONVERSION COMPLETE!")
    print("="*70)
    
    print(f"\n📄 Output file: {gguf_file}")
    print(f"📊 File size: {file_size / (1024 * 1024):.2f} MB")
    print(f"🔐 SHA256: {sha256}")
    
    print("\n📝 Next steps:")
    print("1. Upload to HuggingFace:")
    print(f"   huggingface-cli upload abdulhafis/growwithme-nana-slm-gguf {gguf_file}")
    print("\n2. Update backend/scripts/deploy_slm.js with:")
    print(f"   sha256: '{sha256}'")
    print(f"   sizeBytes: {file_size}")
    print(f"   url: 'https://huggingface.co/abdulhafis/growwithme-nana-slm-gguf/resolve/main/{Path(gguf_file).name}'")
    print("\n3. Run: node backend/scripts/deploy_slm.js")
    print("\n4. Test in Flutter app!")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
