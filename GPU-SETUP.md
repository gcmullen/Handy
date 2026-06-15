# GPU Setup (NVIDIA CUDA) — Handy GPU build

This fork ships an **NVIDIA-accelerated** build of Handy. The Parakeet speech-to-text
model runs on your GPU via ONNX Runtime's CUDA execution provider, which is **5–10×
faster** than CPU on a modern card.

> **You do not need any of this to run Handy.** The installer bundles everything
> required for the **CPU** path, and Whisper models use **Vulkan** (driver-only, no
> setup). The steps below are only needed to unlock the **CUDA** path for Parakeet.
> If the CUDA libraries are missing, Handy detects this at startup and falls back to
> CPU automatically — it will not crash or error.

---

## What's bundled vs. what you install

| Component | Shipped in the installer? | Notes |
| --- | --- | --- |
| `onnxruntime.dll` + `onnxruntime_providers_cuda.dll` | ✅ Yes | Stock Microsoft ONNX Runtime 1.26.0 GPU build (works on RTX 50-series / Blackwell, sm_120). |
| **CUDA Toolkit 12.x** runtime | ❌ No | You install it (one-time, ~3 GB). |
| **cuDNN 9.x** (for CUDA 12) | ❌ No | You install it (one-time). |
| NVIDIA GPU driver | ❌ No | Almost always already present; update if old. |

The CUDA Toolkit and cuDNN are ~3.5 GB combined and are **not redistributable inside
a third-party installer**, so you download them once from NVIDIA.

---

## Requirements

- An **NVIDIA GPU** (GeForce / RTX / Quadro).
- A recent **NVIDIA driver**. Verify with `nvidia-smi` in a terminal — the top-right
  "CUDA Version" must be **12.x or higher** (13.x drivers are backward compatible with
  the CUDA 12 runtime).
- Windows x64.

---

## Step 1 — Install the CUDA 12.x runtime libraries

You do **not** need the full ~3 GB CUDA Toolkit (compiler, Nsight, samples, docs,
headers). ONNX Runtime's CUDA EP only loads these runtime DLLs from the toolkit:

| DLL | Component |
| --- | --- |
| `cudart64_12.dll` | CUDA Runtime |
| `cublas64_12.dll`, `cublasLt64_12.dll` | cuBLAS |
| `cufft64_11.dll` | cuFFT |

(`cudnn64_9.dll` and friends come from cuDNN — that's Step 2.)

Pick whichever install style you prefer:

**Option A — Custom (Advanced) install (recommended, easy).** Download the **CUDA
Toolkit 12.x** for Windows x64
(<https://developer.nvidia.com/cuda-12-9-0-download-archive>; any 12.x works, 12.9 is
the latest 12-series), run it, and choose **Custom (Advanced)** instead of Express.
Then deselect the bulk you don't need:

- ❌ **Driver components** — *especially* deselect this if your installed GeForce/Studio
  driver is newer than the one bundled, so the toolkit doesn't downgrade it.
- ❌ Nsight Compute / Nsight Systems / Nsight VSE, Visual Studio Integration
- ❌ CUDA Documentation, Samples
- ❌ Under **CUDA → Development** (headers, `.lib`, `nvcc`) — not needed at runtime
- ✅ Keep **CUDA → Runtime / Libraries** (this is where `cudart`, `cuBLAS`, `cuFFT` live)

This sets `CUDA_PATH` for you and cuts the footprint dramatically.

**Option B — Redistributable DLLs only (most minimal, advanced).** Instead of the
installer, download NVIDIA's per-library redist archives for CUDA 12.x —
`cuda_cudart`, `libcublas`, `libcufft` — from
<https://developer.download.nvidia.com/compute/cuda/redist/> and place their `bin\*.dll`
files in a folder, then set `CUDA_PATH` to that folder's parent (so `CUDA_PATH\bin`
contains the DLLs). No installer, just the DLLs Handy actually loads.

Either way, confirm `CUDA_PATH` resolves to a folder whose `bin\` holds the DLLs above:

```
CUDA_PATH = C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.9
```

(Check via *System → Advanced → Environment Variables*.)

> **Why 12.x and not 13?** Our ONNX Runtime build links the CUDA **12** runtime
> (`cudart64_12.dll`) and **cuDNN 9** (`cudnn64_9.dll`). It runs on any CUDA 12.0–12.9
> install. A CUDA **13** toolkit alone will **not** satisfy it — install 12.x.

---

## Step 2 — Install cuDNN 9.x (for CUDA 12)

1. Download **cuDNN 9.x for CUDA 12** (Windows x64):
   <https://developer.nvidia.com/cudnn-downloads> (free NVIDIA account required).
   Only the runtime **`bin\*.dll`** files are needed — if you grab the zip/tar archive
   you can ignore its `include\` and `lib\` folders (those are for compiling). cuDNN's
   DLLs depend on each other, so keep the whole `bin\` set rather than cherry-picking.
2. Run the installer (or extract the archive). The installer places DLLs under a
   path like:

   ```
   C:\Program Files\NVIDIA\CUDNN\v9.x\bin\12.x\
   ```

3. Set a `CUDNN_PATH` environment variable pointing at the cuDNN root (the folder
   that contains `bin\`), e.g.:

   ```
   CUDNN_PATH = C:\Program Files\NVIDIA\CUDNN\v9.x
   ```

   Handy automatically finds the CUDA-12 sub-folder (`bin\12.x`) under this path at
   startup, so you don't need to add it to `PATH` yourself. If you installed cuDNN
   into the CUDA Toolkit directory instead (older layout), `CUDA_PATH` alone is
   enough.

---

## Step 3 — Launch Handy

1. Make sure **Parakeet V2 (NVIDIA GPU)** is selected as the model (it's the
   recommended default on NVIDIA machines).
2. Start Handy and do a test transcription.

To confirm the GPU path is active, check the log (Settings → Debug, or the log file)
for a line like:

```
ORT_DYLIB_PATH set to bundled DLL: ...\resources\onnxruntime\onnxruntime.dll
Prepended CUDA/cuDNN dirs to PATH: ...
```

If CUDA is **not** found you'll instead see:

```
Auto: CUDA runtime / cuDNN DLLs not found — skipping CUDA EP, using CPU
```

…and Handy keeps working on CPU.

---

## Troubleshooting

- **`nvidia-smi` not found** → install / update your NVIDIA driver.
- **Still on CPU after installing CUDA + cuDNN** → confirm `CUDA_PATH` and
  `CUDNN_PATH` are set (reboot or sign out/in so new environment variables apply to
  Handy), and that you installed the **CUDA 12** build of cuDNN, not the CUDA 13 one.
- **`cudnn64_9.dll` / `cudnn_graph64_9.dll` load failure** → your cuDNN DLLs are in a
  version sub-folder (`bin\12.x`) that wasn't on `PATH`. Setting `CUDNN_PATH` (Step 2)
  lets Handy add it automatically; make sure it points at the cuDNN root.
- **Multiple GPUs** → Handy pins device order to PCI bus order and uses device 0. Use
  the GPU device setting in the app if you need a different card.

---

## Acceleration summary

| Model family | Accelerator | Setup needed |
| --- | --- | --- |
| **Parakeet** (ONNX) | **CUDA** (this guide) → CPU fallback | CUDA 12.x + cuDNN 9.x |
| **Whisper** (whisper.cpp) | **Vulkan** | None (driver only) |
