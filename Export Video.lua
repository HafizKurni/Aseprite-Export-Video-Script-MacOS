local dlg = Dialog("Export Video")

-- Check if sprite is saved
if app.sprite then
  if not (string.find(app.sprite.filename, '/') or string.find(app.sprite.filename, '\\')) then
    -- app.alert('Save the file and export the frames first.')
  end
else
  -- app.alert('No file is opened.')
end

-- UI Components
dlg:newrow()
dlg:file{
  id = 'firstFramePath',
  label = 'Choose First Frame:',
  title = 'Select the FIRST exported frame (e.g., 1.png)',
  open = false, save = false, load = true,
  filetypes = {'png', 'jpg'}
}

dlg:newrow()
dlg:file{
  id = 'saveTo',
  label = 'Save Video As:',
  title = 'Choose where to save the video',
  open = false, save = true, load = false,
  filetypes = {'mkv', 'mp4'}
}

dlg:newrow()
dlg:number{
  id = 'loopAmount',
  label = 'Loop Count:',
  text = "1",
  decimals = 0
}

-- Export Button
dlg:newrow()
dlg:button{
  id = "export",
  text = "Export Video",

  onclick = function()
    local data = dlg.data
    local firstFramePath = data.firstFramePath
    local saveTo = data.saveTo
    local loopAmount = data.loopAmount

    if (math.type(loopAmount) ~= "integer") or (loopAmount < 1) then
      -- app.alert('Loop count must be an integer greater than or equal to 1.')
      return
    end
    loopAmount = loopAmount - 1

    if not firstFramePath or not saveTo then
      -- return app.alert('Please choose both a sample frame and a save location.')
    end

    local FramesParentFolder = string.match(firstFramePath, "(.*" .. app.fs.pathSeparator .. ")") or ''
    local saveToParentFolder = string.match(saveTo, "(.*" .. app.fs.pathSeparator .. ")") or ''
    local ffconcatContent = "ffconcat version 1.0\n"
    local sprite = app.sprite

    -- Reject non-ASCII paths
    local function isnt_safe(str)
      return str:match("[\128-\255]") ~= nil
    end
    if isnt_safe(FramesParentFolder) or isnt_safe(saveToParentFolder) or isnt_safe(app.fs.fileTitle(saveTo)) then
      -- app.alert("Only Latin (ASCII) characters are allowed in folder or file names.")
      return
    end

    -- Load config (optional)
    local ffmpeg_log = false
    pcall(function()
      local conf = require "conf"
      ffmpeg_log = conf.log_ffmpeg
    end)

    -- Find matching frame images
    local FolderFiles = app.fs.listFiles(FramesParentFolder)
    local frame_images = {}
    for _, file in ipairs(FolderFiles) do
      if string.match(file, "%." .. app.fs.fileExtension(firstFramePath) .. "$") then
        table.insert(frame_images, file)
      end
    end

    table.sort(frame_images, function(a, b)
      local numA = tonumber(string.match(app.fs.fileTitle(a), "%d+"))
      local numB = tonumber(string.match(app.fs.fileTitle(b), "%d+"))
      if numA and numB then return numA < numB end
      return a < b
    end)

    -- Create ffconcat file
    for i, frame in ipairs(sprite.frames) do
      local img = frame_images[i]
      if not img then break end
      local filename = app.fs.joinPath(FramesParentFolder, img)
      local frameDuration = frame.duration
      ffconcatContent = ffconcatContent .. string.format("file '%s'\nduration %s\n", filename, frameDuration)
    end

    local concatFilePath = saveToParentFolder .. "_info"
    local concatFile = io.open(concatFilePath, "w")
    concatFile:write(ffconcatContent)
    concatFile:close()

    -- FFMPEG command
    local ffmpegPath = "/opt/homebrew/bin/ffmpeg" -- Adjust with your own location ffmpeg (this one from homebrew)
    local report_text = ffmpeg_log and " -report" or ""

    local ffmpegCommand = string.format('"%s" -f concat -safe 0 -y -i "%s" -pix_fmt yuv420p -c:v libx264 -crf 23 -preset veryfast "%s"%s',
      ffmpegPath, concatFilePath, saveTo, report_text)

    print("Running main ffmpeg command:", ffmpegCommand)
    os.execute(ffmpegCommand)

    if not app.fs.isFile(saveTo) then
      -- app.alert("FFmpeg export failed or video not found.\nTry this manually:\n" .. ffmpegCommand)
      return
    end

    -- Looping (using -c copy)
    if loopAmount > 0 then
      local loopSaveTo = app.fs.filePathAndTitle(saveTo) .. '_loop' .. (loopAmount + 1) .. "." .. app.fs.fileExtension(saveTo)
      local loopCommand = string.format('"%s" -y -stream_loop %s -i "%s" -c copy "%s"%s',
        ffmpegPath, loopAmount, saveTo, loopSaveTo, report_text)
      print("Running loop ffmpeg command:", loopCommand)
      os.execute(loopCommand)
      if not app.fs.isFile(loopSaveTo) then
        -- app.alert("Loop video export failed. Try this manually:\n" .. loopCommand)
      else
        -- app.alert("Loop video saved as:\n" .. loopSaveTo)
      end
    else
      -- app.alert("Video exported successfully:\n" .. saveTo)
    end
  end
}

-- Other Buttons
dlg:button{
  id = "cancel",
  text = "Cancel",
  onclick = app.command.Cancel
}

dlg:button{
  id = "help",
  text = "Help",
  onclick = function()
    local helpDlg = Dialog("Help")
    helpDlg:label{ label = "Visit the GitHub repo or check Aseprite scripting documentation." }
    helpDlg:show()
  end
}

dlg:show{ wait = false }
