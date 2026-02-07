; Handy NSIS Installer Hooks
; Checks for NVIDIA CUDA Toolkit and cuDNN prerequisites for GPU acceleration.

!macro NSIS_HOOK_PREINSTALL
  ; Check for CUDA_PATH environment variable
  ReadEnvStr $0 "CUDA_PATH"
  StrCmp $0 "" cuda_missing 0
  IfFileExists "$0\*.*" 0 cuda_missing

  ; Check for CUDNN_PATH environment variable
  ReadEnvStr $1 "CUDNN_PATH"
  StrCmp $1 "" cudnn_missing 0
  IfFileExists "$1\*.*" 0 cudnn_missing

  ; Both found
  Goto done

  cuda_missing:
    MessageBox MB_YESNO|MB_ICONINFORMATION \
      "Handy works best with NVIDIA GPU acceleration, but the CUDA_PATH environment variable is not set.$\n$\n\
      Without CUDA, only CPU-based and Whisper models will be available.$\n\
      GPU-accelerated Parakeet models (fastest, most accurate) require:$\n$\n\
      1. NVIDIA CUDA Toolkit 12.x$\n\
         https://developer.nvidia.com/cuda-downloads$\n$\n\
      2. NVIDIA cuDNN 9.x$\n\
         https://developer.nvidia.com/cudnn-downloads$\n$\n\
      After installing, ensure CUDA_PATH and CUDNN_PATH are set, then restart Handy.$\n$\n\
      Continue installation without GPU support?" \
      IDYES done
    Abort
    Goto done

  cudnn_missing:
    MessageBox MB_YESNO|MB_ICONINFORMATION \
      "CUDA Toolkit was found (CUDA_PATH is set), but CUDNN_PATH is not set.$\n$\n\
      GPU-accelerated Parakeet models require both CUDA and cuDNN.$\n$\n\
      Download and install cuDNN from:$\n\
      https://developer.nvidia.com/cudnn-downloads$\n$\n\
      After installing, ensure CUDNN_PATH is set, then restart Handy.$\n$\n\
      Continue installation without full GPU support?" \
      IDYES done
    Abort

  done:
!macroend
