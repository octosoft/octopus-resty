--[[]

    OctoSAM octo_collect upload server for Octoscan2

    this script builds a minimalistic upload service for transfer  
    of OctoSAM .scan files from the Octoscan2 built-in uploader 
    or from curl for open platforms

    calling configuration must set the $octo_collect_store_path variable
    to point to the directory where uploaded files should be stored

    for more information see:
    https://github.com/openresty/lua-resty-upload

    some ideas taken from:
    https://www.yanxurui.cc/posts/server/2017-03-21-NGINX-as-a-file-server/

    we reject files that are not conforming to OctoSAM naming, also the
    parameter must be called 'upload'.

    in case of duplicate post of the same filename we return HTTP status 303

    test:

    $ curl -F "upload=@506fd54d-834c-429a-b018-eed77a888906.scan" localhost:8080

--]] 

-- in case someone is doing a nosy GET request on us:
if ngx.var.request_method == "GET" then
    ngx.say("OctoSAM octo_collect upload server running - " ..
                os.date('%Y-%m-%d %H:%M:%S'))
    return
end

-- requires only standard modules that are distributed with openresty
local upload = require "resty.upload"
-- local cjson = require "cjson"

-- chunk size for multipart upload (100K), most scan files are around 150K
local chunk_size = 1024 * 100

-- pattern to validate upload filename, allow only Octoscan2 .scan files
local x = "%x"
local t = {x:rep(8), x:rep(4), x:rep(4), x:rep(4), x:rep(12)}
local valid_file_name_pattern = table.concat(t, '%-') .. "%.sca."

-- these variables hold information about the uploading file 
local file
local file_path
local file_path_uploading
local file_name
local file_uploaded
local field_name

-- initialize resty.upload
local form, err = upload:new(chunk_size)

if not form then
    ngx.log(ngx.ERR, "failed to new upload: ", err)
    ngx.exit(500)
end

form:set_timeout(5000) -- 5 sec 

while true do
    
    -- receive chunk from resty.upload
    local typ, res, err = form:read()

    if not typ then
        -- ouch, something went badly wrong
        ngx.status = 500
        ngx.say("failed to read: ", err)
        ngx.exit(500)
        return
    end

    if typ == "header" then
        -- we received a header, extract the original filename using lua pattern (not regex)
        file_name = string.match(res[2], ";%s*filename=\"([^\"]*)\"")
        
        if file_name then

            if not string.match(file_name, valid_file_name_pattern) then
                -- we allow only filenames that conform to the OctoSAM naming convention
                ngx.status = 403
                ngx.say("not allowed")
                ngx.exit(403)
            end

            field_name = string.match(res[2],";%s*name=\"([^\"]*)\"" )
            if not string.match(field_name,"upload.*") then
                -- accept only a form field called "upload" (uploaded too for legacy reasons)
                ngx.status = 403
                ngx.say("not allowed")
                ngx.exit(403)
            end

            -- build the destination file name
            -- OctoSAM import detects duplicate .scan files on their content
            file_path = ngx.var.octo_collect_store_path .. file_name

            -- check for duplicate (already uploaded file) -- possible (if rare race) condiition here
            -- Octoscan2 knows about HTTP Status 303
            -- also the OctoSAM import service recognizes duplicate files on their content - not only on the name
            local f = io.open(file_path,"r")
            if f ~= nil then
                f:close()
                ngx.status = 303
                ngx.say("already uploaded")
                ngx.exit(303)
            end

            -- upload to a temp name
            file_path_uploading = file_path .. ".uploading"
            -- windows requires b for binary here
            file = io.open(file_path_uploading, "wb+")
            file_uploaded = file_name
            if not file then
                ngx.status = 503
                -- log file path but return only relative path to sender
                ngx.log(ngx.ERR, "failed to open store for:  ", file_path_uploading)
                ngx.say("failed to open store")
                ngx.exit(503)
                return
            end
        end
    elseif typ == "body" then
        -- get body chunk and write it to file
        if file then file:write(res) end
    elseif typ == "part_end" then
        -- may receive multiple parts but currently, Octoscan2 sends only one and only "filename" is accepted
        -- in the future Octoscan2 may send more information here (checksum etc)
        if file then
            file:close()
            file = nil
            -- rename after upload is complete, this allows the copy job to ignore files that are not
            -- completely uploaded yet (but can also select on timestamps of course)
            os.rename(file_path_uploading,file_path)
            file_path = nil
            file_path_uploading=nil
            file_name = nil

        end
    elseif typ == "eof" then
        -- end of the multipart post, inform the client
        if file_uploaded then ngx.say(file_uploaded .. " thank you!") end
        break
    else
        -- do nothing
    end
end
