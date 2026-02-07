# Build Instructions

This guide covers how to set up the development environment and build Handy from source across different platforms.

## Prerequisites

### All Platforms

- [Rust](https://rustup.rs/) (latest stable)
- [Bun](https://bun.sh/) package manager
- [Tauri Prerequisites](https://tauri.app/start/prerequisites/)

### Platform-Specific Requirements

#### macOS

- Xcode Command Line Tools
- Install with: `xcode-select --install`

#### Windows

- Microsoft C++ Build Tools
- Visual Studio 2019/2022 with C++ development tools
- Or Visual Studio Build Tools 2019/2022

**For GPU Parakeet model support (optional):**

- [CUDA Toolkit 12.x](https://developer.nvidia.com/cuda-downloads)
- [cuDNN 9.x](https://developer.nvidia.com/cudnn-downloads)
- Set environment variables: `CUDA_PATH` and `CUDNN_PATH` pointing to their install directories

#### Linux

- Build essentials
- ALSA development libraries
- Install with:

  ```bash
  # Ubuntu/Debian
  sudo apt update
  sudo apt install build-essential libasound2-dev pkg-config libssl-dev libvulkan-dev vulkan-tools glslc libgtk-3-dev libwebkit2gtk-4.1-dev libayatana-appindicator3-dev librsvg2-dev patchelf cmake

  # Fedora/RHEL
  sudo dnf groupinstall "Development Tools"
  sudo dnf install alsa-lib-devel pkgconf openssl-devel vulkan-devel \
    gtk3-devel webkit2gtk4.1-devel libappindicator-gtk3-devel librsvg2-devel

  # Arch Linux
  sudo pacman -S base-devel alsa-lib pkgconf openssl vulkan-devel \
    gtk3 webkit2gtk-4.1 libappindicator-gtk3 librsvg
  ```

## Setup Instructions

### 1. Clone the Repository

```bash
git clone git@github.com:cjpais/Handy.git
cd Handy
```

### 2. Install Dependencies

```bash
bun install
```

### 3. Start Dev Server

```bash
bun tauri dev
```

## Windows Build Notes

The Windows build target is `["nsis"]`, producing an NSIS-based installer. The installer includes prerequisite checks that detect whether CUDA Toolkit and cuDNN are installed, and informs users if they are missing (GPU Parakeet models require them).

CUDA and cuDNN are **not bundled** with the installer — they are system prerequisites that users install separately. This keeps the installer size manageable (~94 MB vs ~2.2 GB if bundled).

## GPU Development (Windows)

To develop and test GPU Parakeet models:

1. Install [CUDA Toolkit 12.x](https://developer.nvidia.com/cuda-downloads) and [cuDNN 9.x](https://developer.nvidia.com/cudnn-downloads)
2. Set environment variables:
   ```
   CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.x
   CUDNN_PATH=C:\Program Files\NVIDIA\CUDNN\v9.x
   ```
3. Restart your terminal/IDE so the variables take effect

When both `CUDA_PATH` and `CUDNN_PATH` are set and point to valid directories, the GPU Parakeet models (V2 FP32, V3 FP32) will appear in the model selector at runtime. Without these variables, only CPU models are shown.

ONNX Runtime CUDA DLLs are bundled in `src-tauri/resources/gpu-deps/` and are loaded at runtime when a GPU model is selected.
