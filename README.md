# Export Video (MP4 and MKV) in Aseprite

**Maintained Fork by HafizKurni**  
This is a maintained and improved fork of [zmn-hamid's original project](https://github.com/zmn-hamid/Aseprite-Export-Video-Script) that allows exporting Aseprite animations to MP4 and MKV using FFmpeg.

---

## ✨ What's New in This Fork

1. **Improved Looping Support**  
   - Now uses `ffmpeg -stream_loop` with `-c copy` for efficient looping without re-encoding.
   - Simply set your loop count, and the script handles everything.

2. **Better Compatibility with File Paths**  
   - Supports file names with spaces, underscores, and numbers.
   - Non-ASCII folder names are still restricted (due to FFmpeg limitations), but image names can be in any language.

3. **Accurate Export Verification**  
   - The script verifies the success of FFmpeg execution using file checks, avoiding false failure alerts on macOS and Linux.

4. **Cross-Platform Friendly**  
   - Designed for macOS (tested with Homebrew-installed FFmpeg) and works on Windows/Linux with correct FFmpeg setup.

---

## 🔁 Looping

To loop your exported animation:
- Set **Loop Count** to `2` to play the video twice (1 repeat).
- The script will generate a second file named like `yourvideo_loop2.mp4`.

---

## ⚙️ Prerequisites

- You **must have FFmpeg installed** and added to your system path.

### macOS (Homebrew):
```bash
brew install ffmpeg
```
### Windows:
Follow this guide:
How to Install [FFmpeg on Windows](https://phoenixnap.com/kb/ffmpeg-windows)

### Installation
1. Download the script file
2. Open Aseprite → File > Scripts > Open Scripts Folder
3. Paste the script into the folder
4. Restart Aseprite

### Demo Using Script
![Export Video Demo](https://youtu.be/8DgQN9MsYoA)
