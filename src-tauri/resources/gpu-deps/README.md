# GPU Dependencies

This directory contains ONNX Runtime DLLs bundled with the Handy installer.

## Architecture

- **Bundled (this directory)**: ONNX Runtime DLLs — included in the installer
- **System prerequisites**: CUDA Toolkit 12.x + cuDNN 9.x — must be installed by the user

CUDA and cuDNN DLLs are NOT bundled because they exceed installer size limits (~2GB).
Instead, the installer checks for CUDA/cuDNN at install time and the app detects
them at runtime via `CUDA_PATH` and `CUDNN_PATH` environment variables.

## Bundled DLLs (ONNX Runtime 1.22.0)

- `onnxruntime.dll` — Core runtime
- `onnxruntime_providers_cuda.dll` — CUDA execution provider
- `onnxruntime_providers_shared.dll` — Shared provider utilities

## System Prerequisites for GPU Models

GPU-accelerated Parakeet models require the user to install:

1. **NVIDIA CUDA Toolkit 12.x** — https://developer.nvidia.com/cuda-downloads
2. **NVIDIA cuDNN 9.x** — https://developer.nvidia.com/cudnn-downloads

Without these, the app works in CPU mode with Parakeet INT8 and Whisper models.

## How It Works

- **CI builds**: GitHub Actions downloads ONNX Runtime GPU and places DLLs here
- **Local dev**: `build.rs` copies onnxruntime*.dll from `.onnxruntime/` if present
- **Runtime**: `lib.rs` adds this directory + `CUDA_PATH/bin` to PATH
- **Model visibility**: `model.rs` checks for CUDA and only shows GPU models when detected
