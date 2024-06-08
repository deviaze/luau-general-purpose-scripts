--!strict
-- by dev chrysalis (deviaze)

--[[
      Script rewritten as Luau linguist example.

      I decided to reorganize my messy COMP 3081 directory with a Lune script a few months ago; 
      This is a rewritten & cleaned-up version of that script as an example of a common "general purpose" usecase for Luau + Lune.

      All files I wanted to categorize were associated with a specific unit (a digit #)
            in the form "#-some-notes.docx" (notes) or contained "SA#"/"sa#" somewhere in the filename
      I also wanted to copy all prof's notes to pdf to view directly in vscode.
      So, 
            1. I used tables and string pattern matching to associate files by unit
            2. iterated over the units and 
                  3. moved files into directories, creating new dirs as necessary. 
                  4. used docx2pdf.exe to convert .docx to .pdfs and saved them in the same directory
      
      Note - this is much cleaner than my average "do something quickly in Lune" script 😆 
]]

local CONVERT_PDFS = true
local TEST_RUN = true

local fs = require("@lune/fs")
local process = require("@lune/process")

local directory_files = fs.readDir(".")

local files_by_sa : { [string]: {string} } = {}

local hw_pattern = "[Ss][Aa](%d+)" -- "last-first-SA4.docx" or "SA12.docx" or "last-first_sa1-1.pdf" etc
local notes_pattern = "(%d+)%-.+%.docx" -- "4-git-github-merging.docx" etc 

for _, file_name in directory_files do 
      if fs.isDir(`./{file_name}`) then -- skip directories
            continue 
      end
      
      local digit = file_name:match(hw_pattern) or file_name:match(notes_pattern)
      local index = if digit then `SA{digit}` else nil

      if index then
            index = index:upper()
            local files_array = files_by_sa[index]
            if files_array then
                  table.insert(files_array, file_name)
            else
                  files_by_sa[index] = {file_name}
            end
      end

end

print(files_by_sa)

if TEST_RUN then
      process.exit()
end

for dir_name, new_dir_files in files_by_sa do 
      local new_path = `./{dir_name}`

      if not fs.isDir(new_path) then
            fs.writeDir(new_path)
      end

      for _, file_name in new_dir_files do 
            local file_path = `{new_path}/{file_name}`
            
            fs.move(`./{file_name}`, file_path)
            
            if CONVERT_PDFS and file_name:match(notes_pattern) then
                  print(`Converting {file_path} to pdf...`)
                  
                  local pdf_name = file_name:gsub("%.docx", ".pdf")
                  local result = process.spawn("docx2pdf.exe", {file_path, `{new_path}/{pdf_name}`})

                  if not result.stderr:match("100") then -- there should be a "100" in "100%" in docx2pdf's output
                        print(`PDF conversion failed: ({new_path}/{pdf_name}):`)
                        print(result.stderr) 
                  end
            end
      end
      
      print(`Files added to {dir_name}:`)
      for i, file in fs.readDir(new_path) do 
            print(`+  {i}: {file}`)
      end
end
