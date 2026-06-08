-- ============================================================================
-- Aseprite -> Video (one click)
-- Renders the current sprite's frames, builds an MP4/MKV with FFmpeg,
-- and bakes in your loop count. No manual frame export needed.
-- ============================================================================

-- ---- FFmpeg location -------------------------------------------------------
-- Point this at FFmpeg on your machine (you can also change it in the dialog):
--   macOS (Homebrew, Apple Silicon): /opt/homebrew/bin/ffmpeg
--   macOS (Homebrew, Intel):         /usr/local/bin/ffmpeg
--   Linux:                           /usr/bin/ffmpeg
--   Windows:                         C:\ffmpeg\bin\ffmpeg.exe
local DEFAULT_FFMPEG = "/opt/homebrew/bin/ffmpeg"

-- ---- Pre-checks ------------------------------------------------------------
local sprite = app.sprite
if not sprite then
  return app.alert("No sprite is open.")
end
if not (sprite.filename:find("/") or sprite.filename:find("\\")) then
  return app.alert("Please save your sprite first, then run the export.")
end

-- ---- Dialog ----------------------------------------------------------------
local dlg = Dialog("Export to Video")

dlg:file{
  id = "saveTo",
  label = "Save Video As:",
  title = "Choose where to save the video",
  open = false, save = true, load = false,
  filetypes = { "mp4", "mkv" },
  filename = app.fs.filePathAndTitle(sprite.filename) .. ".mp4",
}
dlg:newrow()
dlg:number{
  id = "loopCount",
  label = "Loop Count:",
  text = "1",            -- 1 = play once, 2 = play twice, ...
  decimals = 0,
}
dlg:newrow()
dlg:entry{
  id = "ffmpegPath",
  label = "FFmpeg Path:",
  text = DEFAULT_FFMPEG,
}
dlg:newrow()
dlg:button{
  id = "export",
  text = "Export Video",
  focus = true,
  onclick = function()
    local data       = dlg.data
    local saveTo     = data.saveTo
    local loopCount  = data.loopCount
    local ffmpegPath = data.ffmpegPath

    -- Validate inputs
    if not saveTo or saveTo == "" then
      return app.alert("Please choose where to save the video.")
    end
    if (math.type(loopCount) ~= "integer") or (loopCount < 1) then
      return app.alert("Loop count must be a whole number of 1 or more.")
    end

    -- FFmpeg + the concat demuxer can choke on non-Latin path characters
    local function notAscii(s) return s and s:match("[\128-\255]") ~= nil end
    if notAscii(saveTo) then
      return app.alert("Please use only Latin (ASCII) characters in the path/filename.")
    end

    local outFolder  = app.fs.filePath(saveTo)
    local tmpDir     = app.fs.joinPath(outFolder, "_video_frames_tmp")
    local concatPath = app.fs.joinPath(outFolder, "_video_concat.txt")

    -- Fresh temp folder for the rendered frames
    app.fs.makeDirectory(tmpDir)

    -- Render every frame to a PNG (fully flattened: all visible layers composited)
    local framePaths = {}
    for i = 1, #sprite.frames do
      local img = Image(sprite.spec)
      img:drawSprite(sprite, i)
      local p = app.fs.joinPath(tmpDir, string.format("%05d.png", i))
      img:saveAs(p)
      framePaths[i] = p
    end

    -- Build the ffconcat list, repeating the whole animation `loopCount` times.
    -- frame.duration is in seconds, which is exactly what the concat demuxer wants,
    -- so per-frame timing is preserved precisely.
    local lines = { "ffconcat version 1.0" }
    for _ = 1, loopCount do
      for i, frame in ipairs(sprite.frames) do
        local safePath = framePaths[i]:gsub("\\", "/")  -- forward slashes are safe everywhere
        lines[#lines + 1] = string.format("file '%s'", safePath)
        lines[#lines + 1] = string.format("duration %s", frame.duration)
      end
    end
    -- Repeat the very last frame so the concat demuxer honors its duration
    lines[#lines + 1] = string.format("file '%s'", framePaths[#sprite.frames]:gsub("\\", "/"))

    local f = io.open(concatPath, "w")
    if not f then
      return app.alert("Couldn't create the temporary list file in:\n" .. outFolder)
    end
    f:write(table.concat(lines, "\n"))
    f:close()

    -- Single-pass FFmpeg encode.
    -- The pad filter rounds width/height up to even numbers (libx264 + yuv420p require it).
    local cmd = string.format(
      '"%s" -f concat -safe 0 -y -i "%s" -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" '
      .. '-pix_fmt yuv420p -c:v libx264 -crf 23 -preset veryfast "%s"',
      ffmpegPath, concatPath, saveTo)
    print("FFmpeg command:\n" .. cmd)
    os.execute(cmd)

    -- Clean up only on success (so a failed run leaves the temp files for debugging)
    if app.fs.isFile(saveTo) then
      for _, p in ipairs(framePaths) do os.remove(p) end
      os.remove(concatPath)
      app.fs.removeDirectory(tmpDir)
      app.alert("Done! Video saved to:\n" .. saveTo)
    else
      app.alert(
        "FFmpeg didn't produce a file.\n\n"
        .. "Check the FFmpeg path is correct, then try running this in a terminal:\n\n"
        .. cmd .. "\n\n(Temp frames kept at: " .. tmpDir .. ")")
    end
  end
}

dlg:button{ id = "cancel", text = "Cancel" }

dlg:show{ wait = false }
