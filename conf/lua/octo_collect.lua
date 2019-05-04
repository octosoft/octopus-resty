--[[]

    Octosoft octo_collect upload server for Octoscan2
    (c) 2019 Octosoft AG, CH6312 Steinahusen, Switzerland

    This script builds a simple upload service for transfer transfer 
    of .scan files from the Octoscan2 built in uploader - or from curl 
    for open platforms

    calling configuration must set the $store_path variable

--]]

local upload = require "resty.upload"
local cjson = require "cjson"
local chunk_size = 1024 * 16

-- initialize lua resty upload
local form, err = upload:new(chunk_size)

local file
local file_path
local file_name
local file_uploaded

if not form then
    ngx.log(ngx.ERR, "failed to new upload: ", err)
    ngx.exit(500)
end

form:set_timeout(5000) -- 5 sec

while true do

    local typ, res, err = form:read()
    
    if not typ then
        ngx.status=500
        ngx.say("failed to read: ", err)
        ngx.exit(500)
        return
    end

    if typ == "header" then
        file_name = string.match(res[2],";%s*filename=\"([^\"]*)\"")
        if file_name then
            -- ngx.say("filename:", file_name)
            -- TODO: sanity check on filename
            file_path = ngx.var.octo_collect_store_path..file_name
            -- TODO: prevent duplicate uploads, give a clear message on duplicates
            file = io.open(file_path,"wb+")
            file_uploaded = file_name
            if not file then
                ngx.status = 503
                -- log file path but return only relative path to sender
                ngx.log(ngx.ERR, "failed to open stroe for:  ", file_path)
                ngx.say("failed to open store for ", file_name)
                ngx.exit(503)
                return
            end
        end
    elseif typ == "body" then
        -- get body chunk
        if file then
            file:write(res)
        end
    elseif typ == "part_end" then
        -- may send multiple parts but only "filename" is accepted
        -- in the future Octoscan2 may send more information (checksum etc)
        if file then
            file:close()
            file=nil
            file_name=nil
        end            
    elseif typ == "eof" then
        if file_uploaded then
            ngx.say(file_uploaded)
        end
        break
    else
        -- do nothing
    end
end
